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

avro_foreignKeyOf = "@foreignKeyOf"
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
        let qname = AvroQualifiedName (Avro.namedNamespace n) (Avro.namedName n)
        let hydraName = avroNameToHydraName qname
        env <- getState
        -- Note: if a named type is redefined (an illegal state for which the Avro spec does not provide a resolution),
        --       we just take the first definition and ignore the second.
        case getAvroHydraAdapter qname env of
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
                        Nothing -> fail $ "unrecognized field for " ++ show qname ++ ": " ++ show k
                        Just (f, ad) -> do
                          v' <- coderEncode (adapterCoder ad) v
                          return $ Field (FieldName k) v'
                  let decodeField (Field (FieldName k) v) = case M.lookup k adaptersByFieldName of
                        Nothing -> fail $ "unrecognized field for " ++ show qname ++ ": " ++ show k
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
            putState $ putAvroHydraAdapter qname ad env
            return ad
          Just ad -> fail $ "Avro named type defined more than once: " ++ show qname
      where
        addElement term typ pk fields = case pk of
          Nothing -> pure ()
          Just f -> case L.filter isPkField fields of
              [] -> pure ()
              [field] -> case fieldTerm field of
                TermLiteral (LiteralString s) -> do
                  let name = Name s
                  let el = Element name term (encodeType typ)
                  env <- getState
                  putState $ env {avroEnvironmentElements = M.insert name el (avroEnvironmentElements env)}
                  return ()
                trm -> unexpected ("string value for the primary key field " ++ Avro.fieldName f) trm
              _ -> fail $ "multiple fields named " ++ Avro.fieldName f
            where
              isPkField field = (unFieldName $ fieldName field) == Avro.fieldName f
        findPrimaryKeyField qname avroFields = case L.filter isPrimaryKeyField avroFields of
          [] -> pure Nothing
          [f] -> pure $ Just f
          _ -> fail $ "multiple primary key fields for " ++ show qname
        prepareField f = do
          fk <- foreignKeyOf f
          ad <- case fk of
            Nothing -> avroHydraAdapter $ Avro.fieldType f
            Just name -> pure $ Adapter False (Avro.fieldType f) (Types.element $ Types.nominal name) coder
              where
                coder = Coder {
                  coderDecode = \(TermElement name) -> pure $ Json.ValueString $ unName name,
                  coderEncode = \json -> do
                    s <- expectString json
                    return $ TermElement $ Name s}
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
      let qname = parseAvroName name
      env <- getState
      case getAvroHydraAdapter qname env of
        Nothing -> fail $ "Referenced Avro type has not been defined: " ++ show qname
        Just ad -> pure ad
    Avro.SchemaUnion u -> fail "Avro unions are not yet supported"
  where
    simpleAdapter typ encode decode = pure $ Adapter False schema typ $ Coder encode decode

avroNameToHydraName :: AvroQualifiedName -> Name
avroNameToHydraName (AvroQualifiedName mns local) = fromQname (Namespace $ Y.fromMaybe "DEFAULT" mns) local

getAvroHydraAdapter :: AvroQualifiedName -> AvroEnvironment m -> Y.Maybe (AvroHydraAdapter m)
getAvroHydraAdapter qname = M.lookup qname . avroEnvironmentNamedAdapters

foreignKeyOf :: Avro.Field -> Flow s (Maybe Name)
foreignKeyOf f = case M.lookup avro_foreignKeyOf $ Avro.fieldAnnotations f of
  Nothing -> pure Nothing
  Just v -> Just . Name <$> expectString v

isPrimaryKeyField :: Avro.Field -> Bool
isPrimaryKeyField f = M.member avro_primaryKey $ Avro.fieldAnnotations f

parseAvroName :: String -> AvroQualifiedName
parseAvroName name = case L.reverse $ Strings.splitOn "." name of
  [local] -> AvroQualifiedName Nothing local
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
