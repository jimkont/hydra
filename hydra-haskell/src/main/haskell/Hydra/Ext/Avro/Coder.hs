module Hydra.Ext.Avro.Coder where

import Hydra.Basics
import Hydra.Core
import Hydra.CoreDecoding
import Hydra.Compute
import Hydra.Module
import Hydra.Monads
import Hydra.Lexical
import Hydra.Rewriting
import Hydra.Adapters.Coders
import Hydra.Util.Formatting
import qualified Hydra.Lib.Strings as Strings
import qualified Hydra.Impl.Haskell.Dsl.Types as Types
import qualified Hydra.Impl.Haskell.Dsl.Terms as Terms
import Hydra.Util.Codetree.Script
import Hydra.Lexical
import Hydra.Adapters.UtilsEtc
import qualified Hydra.Ext.Avro.Schema as Avro
import qualified Hydra.Ext.Json.Model as Json
import Hydra.Ext.Json.Eliminate
import Hydra.CoreEncoding

import qualified Control.Monad as CM
import qualified Data.List as L
import qualified Data.Map as M
import qualified Data.Set as S
import qualified Data.Maybe as Y


data AvroEnvironment m = AvroEnvironment {
  avroEnvironmentNamedAdapters :: M.Map AvroQualifiedName (AvroHydraAdapter m),
  avroEnvironmentNamespace :: Maybe String,
  avroEnvironmentElements :: M.Map Name (Element m)} -- note: only used in the term coders

type AvroHydraAdapter m = Adapter (AvroEnvironment m) (AvroEnvironment m) Avro.Schema (Type m) Json.Value (Term m)

data AvroQualifiedName = AvroQualifiedName (Maybe String) String deriving (Eq, Ord, Show)

data ForeignKey = ForeignKey Name (String -> Name)

data PrimaryKey = PrimaryKey FieldName (String -> Name)

emptyEnvironment = AvroEnvironment M.empty Nothing M.empty

avro_foreignKey = "@foreignKey"
avro_primaryKey = "@primaryKey"

avroHydraAdapter :: (Ord m, Show m) => Avro.Schema -> Flow (AvroEnvironment m) (AvroHydraAdapter m)
avroHydraAdapter schema = case schema of
    Avro.SchemaArray (Avro.Array s) -> do
      ad <- avroHydraAdapter s
      let coder = Coder {
            coderEncode = \(Json.ValueArray vals) -> Terms.list <$> (CM.mapM (coderEncode $ adapterCoder ad) vals),
            coderDecode = \(TermList vals) -> Json.ValueArray <$> (CM.mapM (coderDecode $ adapterCoder ad) vals)}
      return $ Adapter (adapterIsLossy ad) schema (Types.list $ adapterTarget ad) coder
    Avro.SchemaMap (Avro.Map_ s) -> do
      ad <- avroHydraAdapter s
      let pairToHydra (k, v) = do
            v' <- coderEncode (adapterCoder ad) v
            return (Terms.string k, v')
      let coder = Coder {
            coderEncode = \(Json.ValueObject m) -> Terms.map . M.fromList <$> (CM.mapM pairToHydra $ M.toList m),
            coderDecode = \m -> Json.ValueObject <$> Terms.expectMap Terms.expectString (coderDecode (adapterCoder ad)) m}
      return $ Adapter (adapterIsLossy ad) schema (Types.map Types.string $ adapterTarget ad) coder
    Avro.SchemaNamed n -> do
        let ns = Avro.namedNamespace n
        env <- getState
        let lastNs = avroEnvironmentNamespace env
        let nextNs = Y.maybe lastNs Just ns
        putState $ env {avroEnvironmentNamespace = nextNs}

        let qname = AvroQualifiedName nextNs (Avro.namedName n)
        let hydraName = avroNameToHydraName qname

        -- Note: if a named type is redefined (an illegal state for which the Avro spec does not provide a resolution),
        --       we just take the first definition and ignore the second.
        ad <- case getAvroHydraAdapter qname env of
          Just ad -> fail $ "Avro named type defined more than once: " ++ show qname
          Nothing -> do
            ad <- case Avro.namedType n of
              Avro.NamedTypeEnum (Avro.Enum_ syms mdefault) -> simpleAdapter typ encode decode  -- TODO: use default value
                where
                  typ = TypeUnion (RowType hydraName $ toField <$> syms)
                    where
                      toField s = FieldType (FieldName s) Types.unit
                  encode (Json.ValueString s) = pure $ TermUnion (Union hydraName $ Field (FieldName s) Terms.unit)
                  -- Note: we simply trust that data coming from the Hydra side is correct
                  decode (TermUnion (Union _ (Field fn _))) = return $ Json.ValueString $ unFieldName fn
              Avro.NamedTypeFixed (Avro.Fixed size) -> simpleAdapter Types.binary encode decode
                where
                  encode (Json.ValueString s) = pure $ Terms.binary s
                  decode term = Json.ValueString <$> Terms.expectBinary term
              Avro.NamedTypeRecord r -> do
                  let avroFields = Avro.recordFields r
                  adaptersByFieldName <- M.fromList <$> (CM.mapM prepareField avroFields)
                  pk <- findPrimaryKeyField qname avroFields
                  let encodePair (k, v) = case M.lookup k adaptersByFieldName of
                        Nothing -> fail $ "unrecognized field for " ++ showQname qname ++ ": " ++ show k
                        Just (f, ad) -> do
                          v' <- coderEncode (adapterCoder ad) v
                          return $ Field (FieldName k) v'
                  let decodeField (Field (FieldName k) v) = case M.lookup k adaptersByFieldName of
                        Nothing -> fail $ "unrecognized field for " ++ showQname qname ++ ": " ++ show k
                        Just (f, ad) -> do
                          v' <- coderDecode (adapterCoder ad) v
                          return (k, v')
                  let lossy = L.foldl (\b (_, ad) -> b || adapterIsLossy ad) False $ M.elems adaptersByFieldName
                  let hfields = toHydraField <$> M.elems adaptersByFieldName
                  let target = TypeRecord $ RowType hydraName hfields
                  let coder = Coder {
                    -- Note: the order of the fields is changed
                    coderEncode = \(Json.ValueObject m) -> do
                      fields <- CM.mapM encodePair $ M.toList m
                      let term = TermRecord $ Record hydraName fields
                      addElement term target pk fields
                      return term,
                    coderDecode = \(TermRecord (Record _ fields)) -> Json.ValueObject . M.fromList <$> (CM.mapM decodeField fields)}
                  return $ Adapter lossy schema target coder
                where
                  toHydraField (f, ad) = FieldType (FieldName $ Avro.fieldName f) $ adapterTarget ad
            env <- getState
            putState $ putAvroHydraAdapter qname ad env
            return ad

        env2 <- getState
        putState $ env2 {avroEnvironmentNamespace = lastNs}
        return ad
      where
        addElement term typ pk fields = case pk of
          Nothing -> pure ()
          Just (PrimaryKey fname constr) -> case L.filter isPkField fields of
              [] -> pure ()
              [field] -> do
                  s <- termToString $ fieldTerm field
                  let name = constr s
                  let el = Element name (encodeType typ) term
                  env <- getState
                  putState $ env {avroEnvironmentElements = M.insert name el (avroEnvironmentElements env)}
                  return ()
              _ -> fail $ "multiple fields named " ++ unFieldName fname
            where
              isPkField field = fieldName field == fname
        findPrimaryKeyField qname avroFields = do
          keys <- Y.catMaybes <$> CM.mapM primaryKey avroFields
          case keys of
            [] -> pure Nothing
            [k] -> pure $ Just k
            _ -> fail $ "multiple primary key fields for " ++ show qname
        prepareField f = do
          fk <- foreignKey f
          ad <- case fk of
            Nothing -> avroHydraAdapter $ Avro.fieldType f
            Just (ForeignKey name constr) -> pure $ Adapter False (Avro.fieldType f) (Types.element $ Types.nominal name) coder
              where
                coder = Coder {
                  coderDecode = \(TermElement name) -> pure $ Json.ValueString $ unName name, -- TODO: not symmetrical
                  coderEncode = \json -> do
                    s <- jsonToString json
                    return $ TermElement $ constr s}
          return (Avro.fieldName f, (f, ad))
    Avro.SchemaPrimitive p -> case p of
        Avro.PrimitiveNull -> simpleAdapter Types.unit encode decode
          where
            encode (Json.ValueString s) = pure $ Terms.string s
            decode term = Json.ValueString <$> Terms.expectString term
        Avro.PrimitiveBoolean -> simpleAdapter Types.boolean encode decode
          where
            encode (Json.ValueBoolean b) = pure $ Terms.boolean b
            decode term = Json.ValueBoolean <$> Terms.expectBoolean term
        Avro.PrimitiveInt -> simpleAdapter Types.int32 encode decode
          where
            encode (Json.ValueNumber d) = pure $ Terms.int32 $ doubleToInt d
            decode term = Json.ValueNumber . fromIntegral <$> Terms.expectInt32 term
        Avro.PrimitiveLong -> simpleAdapter Types.int64 encode decode
          where
            encode (Json.ValueNumber d) = pure $ Terms.int32 $ doubleToInt d
            decode term = Json.ValueNumber . fromIntegral <$> Terms.expectInt64 term
        Avro.PrimitiveFloat -> simpleAdapter Types.float32 encode decode
          where
            encode (Json.ValueNumber d) = pure $ Terms.float32 $ realToFrac d
            decode term = Json.ValueNumber . realToFrac <$> Terms.expectFloat32 term
        Avro.PrimitiveDouble -> simpleAdapter Types.float64 encode decode
          where
            encode (Json.ValueNumber d) = pure $ Terms.float64 d
            decode term = Json.ValueNumber <$> Terms.expectFloat64 term
        Avro.PrimitiveBytes -> simpleAdapter Types.binary encode decode
          where
            encode (Json.ValueString s) = pure $ Terms.binary s
            decode term = Json.ValueString <$> Terms.expectBinary term
        Avro.PrimitiveString -> simpleAdapter Types.string encode decode
          where
            encode (Json.ValueString s) = pure $ Terms.string s
            decode term = Json.ValueString <$> Terms.expectString term
      where
        doubleToInt d = if d < 0 then ceiling d else floor d
    Avro.SchemaReference name -> do
      env <- getState
      let qname = parseAvroName (avroEnvironmentNamespace env) name
      case getAvroHydraAdapter qname env of
        Nothing -> fail $ "Referenced Avro type has not been defined: " ++ show qname
         ++ ". Defined types: " ++ show (M.keys $ avroEnvironmentNamedAdapters env)
        Just ad -> pure ad
    Avro.SchemaUnion (Avro.Union schemas) -> if L.length nonNulls > 1
        then fail $ "general-purpose unions are not yet supported: " ++ show schema
        else if L.null nonNulls
        then fail $ "cannot generate the empty type"
        else if hasNull
        then forOptional $ L.head nonNulls
        else do
          ad <- avroHydraAdapter $ L.head nonNulls
          return $ Adapter (adapterIsLossy ad) schema (adapterTarget ad) (adapterCoder ad)
      where
        hasNull = (not . L.null . L.filter isNull) schemas
        nonNulls = L.filter (not . isNull) schemas
        isNull schema = case schema of
          Avro.SchemaPrimitive Avro.PrimitiveNull -> True
          _ -> False
        forOptional s = do
          ad <- avroHydraAdapter s
          let coder = Coder {
                coderDecode = \(TermOptional ot) -> case ot of
                  Nothing -> pure $ Json.ValueNull
                  Just term -> coderDecode (adapterCoder ad) term,
                coderEncode = \v -> case v of
                  Json.ValueNull -> pure $ TermOptional Nothing
                  _ -> TermOptional . Just <$> coderEncode (adapterCoder ad) v}
          return $ Adapter (adapterIsLossy ad) schema (Types.optional $ adapterTarget ad) coder
  where
    simpleAdapter typ encode decode = pure $ Adapter False schema typ $ Coder encode decode

avroNameToHydraName :: AvroQualifiedName -> Name
avroNameToHydraName (AvroQualifiedName mns local) = fromQname (Namespace $ Y.fromMaybe "DEFAULT" mns) local

getAvroHydraAdapter :: AvroQualifiedName -> AvroEnvironment m -> Y.Maybe (AvroHydraAdapter m)
getAvroHydraAdapter qname = M.lookup qname . avroEnvironmentNamedAdapters

foreignKey :: Avro.Field -> Flow s (Maybe ForeignKey)
foreignKey f = case M.lookup avro_foreignKey (Avro.fieldAnnotations f) of
    Nothing -> pure Nothing
    Just v -> do
      m <- expectObject v
      tname <- Name <$> requireString "type" m
      pattern <- optString "pattern" m
      let constr = case pattern of
            Nothing -> Name
            Just pat -> patternToNameConstructor pat
      return $ Just $ ForeignKey tname constr

patternToNameConstructor :: String -> String -> Name
patternToNameConstructor pat = \s -> Name $ L.intercalate s $ Strings.splitOn "${}" pat

primaryKey :: Avro.Field -> Flow s (Maybe PrimaryKey)
primaryKey f = do
  case M.lookup avro_primaryKey $ Avro.fieldAnnotations f of
    Nothing -> pure Nothing
    Just v -> do
      s <- expectString v
      return $ Just $ PrimaryKey (FieldName $ Avro.fieldName f) $ patternToNameConstructor s

parseAvroName :: Maybe String -> String -> AvroQualifiedName
parseAvroName mns name = case L.reverse $ Strings.splitOn "." name of
  [local] -> AvroQualifiedName mns local
  (local:rest) -> AvroQualifiedName (Just $ L.intercalate "." $ L.reverse rest) local

putAvroHydraAdapter :: AvroQualifiedName -> AvroHydraAdapter m -> AvroEnvironment m -> AvroEnvironment m
putAvroHydraAdapter qname ad env = env {avroEnvironmentNamedAdapters = M.insert qname ad $ avroEnvironmentNamedAdapters env}

rewriteAvroSchemaM :: ((Avro.Schema -> Flow s Avro.Schema) -> Avro.Schema -> Flow s Avro.Schema) -> Avro.Schema -> Flow s Avro.Schema
rewriteAvroSchemaM f = rewrite fsub f
  where
    fsub recurse schema = case schema of
        Avro.SchemaArray (Avro.Array els) -> Avro.SchemaArray <$> (Avro.Array <$> recurse els)
        Avro.SchemaMap (Avro.Map_ vschema) -> Avro.SchemaMap <$> (Avro.Map_ <$> recurse vschema)
        Avro.SchemaNamed n -> do
          nt <- case Avro.namedType n of
            Avro.NamedTypeRecord (Avro.Record fields) -> Avro.NamedTypeRecord <$> (Avro.Record <$> (CM.mapM forField fields))
            t -> pure t
          return $ Avro.SchemaNamed $ n {Avro.namedType = nt}
        Avro.SchemaUnion (Avro.Union schemas) -> Avro.SchemaUnion <$> (Avro.Union <$> (CM.mapM recurse schemas))
        _ -> pure schema
      where
        forField f = do
          t <- recurse $ Avro.fieldType f
          return f {Avro.fieldType = t}

jsonToString :: Json.Value -> Flow s String
jsonToString v = case v of
  Json.ValueBoolean b -> pure $ if b then "true" else "false"
  Json.ValueString s -> pure s
  Json.ValueNumber d -> pure $ if fromIntegral (round d) == d
    then show (round d)
    else show d
  _ -> unexpected "string, number, or boolean" v

showQname :: AvroQualifiedName -> String
showQname (AvroQualifiedName mns local) = (Y.maybe "" (\ns -> ns ++ ".") mns) ++ local

termToString :: Show m => Term m -> Flow s String
termToString term = case stripTerm term of
  TermLiteral l -> case l of
    LiteralBoolean b -> pure $ show b
    LiteralInteger iv -> pure $ case iv of
      IntegerValueBigint i -> show i
      IntegerValueInt8 i -> show i
      IntegerValueInt16 i -> show i
      IntegerValueInt32 i -> show i
      IntegerValueInt64 i -> show i
      IntegerValueUint8 i -> show i
      IntegerValueUint16 i -> show i
      IntegerValueUint32 i -> show i
      IntegerValueUint64 i -> show i
    LiteralString s -> pure s
    _ -> unexpected "boolean, integer, or string" l
  _ -> unexpected "literal value" term
