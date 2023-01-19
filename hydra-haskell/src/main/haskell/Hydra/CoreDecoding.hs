-- | Decoding of encoded types (as terms) back to types

module Hydra.CoreDecoding (
  decodeLiteralType,
  decodeFieldType,
  decodeFieldTypes,
  decodeFloatType,
  decodeFunctionType,
  decodeIntegerType,
  decodeMapType,
  decodeRowType,
  decodeString,
  decodeType,
  decodeLambdaType,
  elementAsTypedTerm,
  fieldTypes,
  requireRecordType,
  requireType,
  requireUnionType,
  typeDependencies,
  typeDependencyNames,
  ) where

import Hydra.Common
import Hydra.Core
import Hydra.Mantle
import Hydra.Module
import Hydra.Lexical
import Hydra.Monads
import Hydra.Rewriting
import qualified Hydra.Impl.Haskell.Dsl.Terms as Terms

import qualified Control.Monad as CM
import qualified Data.List as L
import qualified Data.Map as M
import qualified Data.Set as S


decodeApplicationType :: Show m => Term m -> GraphFlow m (ApplicationType m)
decodeApplicationType = matchRecord $ \m -> ApplicationType
  <$> getField m _ApplicationType_function decodeType
  <*> getField m _ApplicationType_argument decodeType

decodeElement :: Show m => Term m -> GraphFlow m Name
decodeElement term = case stripTerm term of
  TermElement name -> pure name
  _ -> unexpected "element" term

decodeFieldType :: Show m => Term m -> GraphFlow m (FieldType m)
decodeFieldType = matchRecord $ \m -> FieldType
  <$> (FieldName <$> getField m _FieldType_name decodeString)
  <*> getField m _FieldType_type decodeType

decodeFieldTypes :: Show m => Term m -> GraphFlow m [FieldType m]
decodeFieldTypes term = case stripTerm term of
  TermList els -> CM.mapM decodeFieldType els
  _ -> unexpected "list" term

decodeFloatType :: Show m => Term m -> GraphFlow m FloatType
decodeFloatType = matchEnum [
  (_FloatType_bigfloat, FloatTypeBigfloat),
  (_FloatType_float32, FloatTypeFloat32),
  (_FloatType_float64, FloatTypeFloat64)]

decodeFunctionType :: Show m => Term m -> GraphFlow m (FunctionType m)
decodeFunctionType = matchRecord $ \m -> FunctionType
  <$> getField m _FunctionType_domain decodeType
  <*> getField m _FunctionType_codomain decodeType

decodeIntegerType :: Show m => Term m -> GraphFlow m IntegerType
decodeIntegerType = matchEnum [
  (_IntegerType_bigint, IntegerTypeBigint),
  (_IntegerType_int8, IntegerTypeInt8),
  (_IntegerType_int16, IntegerTypeInt16),
  (_IntegerType_int32, IntegerTypeInt32),
  (_IntegerType_int64, IntegerTypeInt64),
  (_IntegerType_uint8, IntegerTypeUint8),
  (_IntegerType_uint16, IntegerTypeUint16),
  (_IntegerType_uint32, IntegerTypeUint32),
  (_IntegerType_uint64, IntegerTypeUint64)]

decodeLambdaType :: Show m => Term m -> GraphFlow m (LambdaType m)
decodeLambdaType = matchRecord $ \m -> LambdaType
  <$> (VariableType <$> getField m _LambdaType_parameter decodeString)
  <*> getField m _LambdaType_body decodeType

decodeLiteralType :: Show m => Term m -> GraphFlow m LiteralType
decodeLiteralType = matchUnion [
  matchUnitField _LiteralType_binary LiteralTypeBinary,
  matchUnitField _LiteralType_boolean LiteralTypeBoolean,
  (_LiteralType_float, fmap LiteralTypeFloat . decodeFloatType),
  (_LiteralType_integer, fmap LiteralTypeInteger . decodeIntegerType),
  matchUnitField _LiteralType_string LiteralTypeString]

decodeMapType :: Show m => Term m -> GraphFlow m (MapType m)
decodeMapType = matchRecord $ \m -> MapType
  <$> getField m _MapType_keys decodeType
  <*> getField m _MapType_values decodeType

decodeRowType :: Show m => Term m -> GraphFlow m (RowType m)
decodeRowType = matchRecord $ \m -> RowType
  <$> (Name <$> getField m _RowType_typeName decodeString)
  <*> getField m _RowType_extends (Terms.expectOptional (\term -> Name <$> Terms.expectString term))
  <*> getField m _RowType_fields decodeFieldTypes

decodeString :: Show m => Term m -> GraphFlow m String
decodeString = Terms.expectString . stripTerm

decodeType :: Show m => Term m -> GraphFlow m (Type m)
decodeType dat = case dat of
  TermElement name -> pure $ TypeWrapped name
  TermAnnotated (Annotated term ann) -> (\t -> TypeAnnotated $ Annotated t ann) <$> decodeType term
  _ -> matchUnion [
--    (_Type_annotated, fmap TypeAnnotated . decodeAnnotated),
    (_Type_application, fmap TypeApplication . decodeApplicationType),
    (_Type_element, fmap TypeElement . decodeType),
    (_Type_function, fmap TypeFunction . decodeFunctionType),
    (_Type_lambda, fmap TypeLambda . decodeLambdaType),
    (_Type_list, fmap TypeList . decodeType),
    (_Type_literal, fmap TypeLiteral . decodeLiteralType),
    (_Type_map, fmap TypeMap . decodeMapType),
    (_Type_wrapped, fmap TypeWrapped . decodeElement),
    (_Type_optional, fmap TypeOptional . decodeType),
    (_Type_product, \(TermList types) -> TypeProduct <$> (CM.mapM decodeType types)),
    (_Type_record, fmap TypeRecord . decodeRowType),
    (_Type_set, fmap TypeSet . decodeType),
    (_Type_sum, \(TermList types) -> TypeSum <$> (CM.mapM decodeType types)),
    (_Type_union, fmap TypeUnion . decodeRowType),
    (_Type_variable, fmap (TypeVariable . VariableType) . decodeString)] dat

elementAsTypedTerm :: (Show m) => Element m -> GraphFlow m (TypedTerm m)
elementAsTypedTerm el = TypedTerm <$> decodeType (elementSchema el) <*> pure (elementData el)

fieldTypes :: Show m => Type m -> GraphFlow m (M.Map FieldName (Type m))
fieldTypes t = case stripType t of
    TypeRecord rt -> pure $ toMap $ rowTypeFields rt
    TypeUnion rt -> pure $ toMap $ rowTypeFields rt
    TypeElement et -> fieldTypes et
    TypeWrapped name -> do
      withTrace ("field types of " ++ unName name) $ do
        el <- requireElement name
        decodeType (elementData el) >>= fieldTypes
    TypeLambda (LambdaType _ body) -> fieldTypes body
    _ -> unexpected "record or union type" t
  where
    toMap fields = M.fromList (toPair <$> fields)
    toPair (FieldType fname ftype) = (fname, ftype)

getField :: M.Map FieldName (Term m) -> FieldName -> (Term m -> GraphFlow m b) -> GraphFlow m b
getField m fname decode = case M.lookup fname m of
  Nothing -> fail $ "expected field " ++ show fname ++ " not found"
  Just val -> decode val

matchEnum :: Show m => [(FieldName, b)] -> Term m -> GraphFlow m b
matchEnum = matchUnion . fmap (uncurry matchUnitField)

matchRecord :: Show m => (M.Map FieldName (Term m) -> GraphFlow m b) -> Term m -> GraphFlow m b
matchRecord decode term = do
  term1 <- deref term
  case stripTerm term1 of
    TermRecord (Record _ fields) -> decode $ M.fromList $ fmap (\(Field fname val) -> (fname, val)) fields
    _ -> unexpected "record" term1

matchUnion :: Show m => [(FieldName, Term m -> GraphFlow m b)] -> Term m -> GraphFlow m b
matchUnion pairs term = do
    term1 <- deref term
    case stripTerm term1 of
      TermUnion (Union _ (Field fname val)) -> case M.lookup fname mapping of
        Nothing -> fail $ "no matching case for field " ++ show fname
        Just f -> f val
      _ -> unexpected ("union with one of {" ++ L.intercalate ", " (unFieldName . fst <$> pairs) ++ "}") term
  where
    mapping = M.fromList pairs

matchUnitField :: FieldName -> b -> (FieldName, a -> GraphFlow m b)
matchUnitField fname x = (fname, \_ -> pure x)

requireRecordType :: Show m => Bool -> Name -> GraphFlow m (RowType m)
requireRecordType infer = requireRowType "record" infer $ \t -> case t of
  TypeRecord rt -> Just rt
  _ -> Nothing

requireRowType :: Show m => String -> Bool -> (Type m -> Maybe (RowType m)) -> Name -> GraphFlow m (RowType m)
requireRowType label infer getter name = do
  t <- withSchemaContext $ requireType name
  case getter (rawType t) of
    Just rt -> if infer
      then case rowTypeExtends rt of
        Nothing -> return rt
        Just name' -> do
          rt' <- requireRowType label True getter name'
          return $ RowType name Nothing (rowTypeFields rt' ++ rowTypeFields rt)
      else return rt
    Nothing -> fail $ show name ++ " does not resolve to a " ++ label ++ " type: " ++ show t
  where
    rawType t = case t of
      TypeAnnotated (Annotated t' _) -> rawType t'
      TypeLambda (LambdaType _ body) -> rawType body -- Note: throwing away quantification here
      _ -> t

requireType :: Show m => Name -> GraphFlow m (Type m)
requireType name = withTrace "require type" $ do
  el <- requireElement name
  decodeType $ elementData el

requireUnionType :: Show m => Bool -> Name -> GraphFlow m (RowType m)
requireUnionType infer = requireRowType "union" infer $ \t -> case t of
  TypeUnion rt -> Just rt
  _ -> Nothing

typeDependencies :: Show m => Name -> GraphFlow m (M.Map Name (Type m))
typeDependencies name = deps (S.fromList [name]) M.empty
  where
    deps seeds names = if S.null seeds
        then return names
        else do
          pairs <- CM.mapM toPair $ S.toList seeds
          let newNames = M.union names (M.fromList pairs)
          let refs = L.foldl S.union S.empty (typeDependencyNames <$> (snd <$> pairs))
          let visited = S.fromList $ M.keys names
          let newSeeds = S.difference refs visited
          deps newSeeds newNames
      where
        toPair name = do
          typ <- requireType name
          return (name, typ)

    requireType name = do
      withTrace ("type dependencies of " ++ unName name) $ do
        el <- requireElement name
        decodeType (elementData el)

typeDependencyNames :: Type m -> S.Set Name
typeDependencyNames = foldOverType TraversalOrderPre addNames S.empty
  where
    addNames names typ = case typ of
      TypeWrapped name -> S.insert name names
      _ -> names
