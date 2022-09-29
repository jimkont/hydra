module Hydra.Ext.Shacl.Coder where

import Hydra.Common
import Hydra.Core
import Hydra.Compute
import Hydra.Module
import Hydra.Monads
import Hydra.CoreDecoding
import Hydra.Lexical
import qualified Hydra.Ext.Rdf.Syntax as Rdf
import qualified Hydra.Ext.Shacl.Model as Shacl
import qualified Hydra.Impl.Haskell.Dsl.Literals as Literals
import qualified Hydra.Impl.Haskell.Dsl.Terms as Terms
import Hydra.Util.Formatting

import qualified Control.Monad as CM
import qualified Data.List as L
import qualified Data.Map as M
import qualified Data.Set as S
import qualified Data.Maybe as Y


nodeCount = "nodeCount"

shaclCoder :: (Eq m, Show m) => Module m -> GraphFlow m (Shacl.ShapesGraph, Graph m -> GraphFlow m Rdf.Graph)
shaclCoder mod = do
    cx <- getState
    let typeEls = L.filter (isEncodedType cx . elementSchema) $ moduleElements mod
    shapes <- CM.mapM toShape typeEls
    let sg = Shacl.ShapesGraph $ S.fromList shapes
    let termFlow = \g -> do
          fail "not implemented"
    return (sg, termFlow)
  where
    toShape el = do
      typ <- decodeType $ elementData el
      common <- encodeType typ
      return $ Shacl.Definition (elementIri el) $ Shacl.ShapeNode $ Shacl.NodeShape common

common :: [Shacl.CommonConstraint] -> Shacl.CommonProperties
common constraints = defaultCommonProperties {
  Shacl.commonPropertiesConstraints = S.fromList constraints}

defaultCommonProperties :: Shacl.CommonProperties
defaultCommonProperties = Shacl.CommonProperties {
  Shacl.commonPropertiesConstraints = S.empty,
  Shacl.commonPropertiesDeactivated = Nothing,
  Shacl.commonPropertiesMessage = emptyLangStrings,
  Shacl.commonPropertiesSeverity = Shacl.SeverityInfo,
  Shacl.commonPropertiesTargetClass = S.empty,
  Shacl.commonPropertiesTargetNode = S.empty,
  Shacl.commonPropertiesTargetObjectsOf = S.empty,
  Shacl.commonPropertiesTargetSubjectsOf = S.empty}

descriptionsToGraph :: [Rdf.Description] -> Rdf.Graph
descriptionsToGraph ds = Rdf.Graph $ S.fromList $ triplesOf ds

elementIri :: Element m -> Rdf.Iri
elementIri = nameToIri . elementName

emptyDescription :: Rdf.Node -> Rdf.Description
emptyDescription node = Rdf.Description node emptyGraph

emptyGraph :: Rdf.Graph
emptyGraph = Rdf.Graph S.empty

emptyLangStrings :: Rdf.LangStrings
emptyLangStrings = Rdf.LangStrings M.empty

encodeField :: Show m => Name -> Rdf.Resource -> Field m -> GraphFlow m [Rdf.Triple]
encodeField rname subject field = do
  descs <- encodeTerm (fieldTerm field)
  return $ triplesOf descs ++
    forObjects subject (propertyIri rname $ fieldName field) (subjectsOf descs)

encodeFieldType :: Show m => Name -> Maybe Integer -> FieldType m -> GraphFlow m (Shacl.Definition Shacl.PropertyShape)
encodeFieldType rname order (FieldType fname ft) = do
    shape <- forType (Just 1) (Just 1) ft
    return $ Shacl.Definition iri shape
  where
    iri = propertyIri rname fname
    forType mn mx t = case stripType t of
      TypeOptional ot -> forType (Just 0) mx ot
      TypeSet st -> forType mn Nothing st
      _ -> do
        cp <- encodeType t
        let baseProp = property iri
        return $ baseProp {
          Shacl.propertyShapeCommon = cp,
          Shacl.propertyShapeConstraints = S.fromList $ Y.catMaybes [
            Shacl.PropertyShapeConstraintMinCount <$> mn,
            Shacl.PropertyShapeConstraintMaxCount <$> mx],
          Shacl.propertyShapeOrder = order}

encodeLiteral :: Literal -> GraphFlow m Rdf.Node
encodeLiteral lit = Rdf.NodeLiteral <$> case lit of
    LiteralBinary s -> fail "base 64 encoding not yet implemented"
    LiteralBoolean b -> pure $ xsd (\b -> if b then "true" else "false") b "boolean"
    LiteralFloat f -> pure $ case f of
      FloatValueBigfloat v -> xsd show v "decimal"
      FloatValueFloat32 v -> xsd show v "float"
      FloatValueFloat64 v -> xsd show v "double"
    LiteralInteger i -> pure $ case i of
      IntegerValueBigint v -> xsd show v "integer"
      IntegerValueInt8 v   -> xsd show v "byte"
      IntegerValueInt16 v  -> xsd show v "short"
      IntegerValueInt32 v  -> xsd show v "int"
      IntegerValueInt64 v  -> xsd show v "long"
      IntegerValueUint8 v  -> xsd show v "unsignedByte"
      IntegerValueUint16 v -> xsd show v "unsignedShort"
      IntegerValueUint32 v -> xsd show v "unsignedInt"
      IntegerValueUint64 v -> xsd show v "unsignedLong"
    LiteralString s -> pure $ xsd id s "string"
  where
    -- TODO: using Haskell's built-in show function is a cheat, and may not be correct/optimal in all cases
    xsd ser x local = Rdf.Literal (ser x) (xmlSchemaDatatypeIri local) Nothing

encodeLiteralType :: LiteralType -> Shacl.CommonProperties
encodeLiteralType lt = case lt of
    LiteralTypeBinary -> xsd "base64Binary"
    LiteralTypeBoolean -> xsd "boolean"
    LiteralTypeFloat ft -> case ft of
      FloatTypeBigfloat -> xsd "decimal"
      FloatTypeFloat32 -> xsd "float"
      FloatTypeFloat64 -> xsd "double"
    LiteralTypeInteger it -> case it of
      IntegerTypeBigint -> xsd "integer"
      IntegerTypeInt8 -> xsd "byte"
      IntegerTypeInt16 -> xsd "short"
      IntegerTypeInt32 -> xsd "int"
      IntegerTypeInt64 -> xsd "long"
      IntegerTypeUint8 -> xsd "unsignedByte"
      IntegerTypeUint16 -> xsd "unsignedShort"
      IntegerTypeUint32 -> xsd "unsignedInt"
      IntegerTypeUint64 -> xsd "unsignedLong"
    LiteralTypeString -> xsd "string"
  where
    xsd local = common [Shacl.CommonConstraintDatatype $ xmlSchemaDatatypeIri local]

encodeTerm :: Show m => Term m -> GraphFlow m [Rdf.Description]
encodeTerm term = case term of
  TermAnnotated (Annotated inner ann) -> encodeTerm inner -- TODO: extract an rdfs:comment
  TermElement name -> pure [emptyDescription $ Rdf.NodeIri $ nameToIri name]
  TermList terms -> encodeList terms
    where
      encodeList terms = if L.null terms
        then pure [emptyDescription $ (Rdf.NodeIri $ rdfIri "nil")]
          else do
            node <- nextBlankNode
            fdescs <- encodeTerm $ L.head terms
            let firstTriples = triplesOf fdescs ++
                  forObjects (Rdf.ResourceBnode node) (rdfIri "first") (subjectsOf fdescs)
            rdescs <- encodeList $ L.tail terms
            let restTriples = triplesOf rdescs ++
                  forObjects (Rdf.ResourceBnode node) (rdfIri "rest") (subjectsOf rdescs)
            return [Rdf.Description (Rdf.NodeBnode node) (Rdf.Graph $ S.fromList $ firstTriples ++ restTriples)]
  TermLiteral lit -> do
    node <- encodeLiteral lit
    return [emptyDescription node]
  TermMap m -> do
      bnode <- nextBlankNode
      triples <- L.concat <$> (CM.mapM (forKeyVal $ Rdf.ResourceBnode bnode) $ M.toList m)
      return [Rdf.Description (Rdf.NodeBnode bnode) $ Rdf.Graph $ S.fromList triples]
    where
      forKeyVal subj (k, v) = do
        -- Note: only string-valued keys are supported
        ks <- Terms.expectString $ stripTerm k
        descs <- encodeTerm v
        let pred = keyIri ks
        let objs = subjectsOf descs
        let triples = forObjects subj pred objs
        return $ triples ++ triplesOf descs
  TermNominal (Named _ inner) -> encodeTerm inner
  TermOptional mterm -> case mterm of
    Nothing -> pure []
    Just inner -> encodeTerm inner
  TermRecord (Record rname fields) -> do
    node <- nextBlankNode
    tripless <- CM.mapM (encodeField rname (Rdf.ResourceBnode node)) fields
    return [Rdf.Description (Rdf.NodeBnode node) (Rdf.Graph $ S.fromList $ L.concat tripless)]
  TermSet terms -> L.concat <$> CM.mapM encodeTerm (S.toList terms)
  TermUnion (Union rname field) -> do
    node <- nextBlankNode
    triples <- encodeField rname (Rdf.ResourceBnode node) field
    return [Rdf.Description (Rdf.NodeBnode node) (Rdf.Graph $ S.fromList triples)]
  _ -> unexpected "RDF-compatible term" term

encodeType :: Show m => Type m -> GraphFlow m Shacl.CommonProperties
encodeType typ = case stripType typ of
    TypeElement et -> encodeType et
    TypeList _ -> any
    TypeLiteral lt -> pure $ encodeLiteralType lt
    TypeMap _ -> any
    TypeNominal name -> any -- TODO: include name
    TypeRecord (RowType rname fields) -> do
      props <- CM.zipWithM (encodeFieldType rname) (Just <$> [0..]) fields
      return $ common [Shacl.CommonConstraintProperty $ S.fromList (Shacl.ReferenceDefinition <$> props)]
    TypeSet _ -> any
    TypeUnion (RowType rname fields) -> do
        props <- CM.mapM (encodeFieldType rname Nothing) fields
        let shapes = (Shacl.ReferenceAnonymous . toShape) <$> props
        return $ common [Shacl.CommonConstraintXone $ S.fromList shapes]
      where
        toShape prop = node [Shacl.CommonConstraintProperty $ S.fromList [Shacl.ReferenceDefinition prop]]
    _ -> unexpected "type" typ
  where
    -- SHACL's built-in vocabulary is less expressive than Hydra's type system, so for now, SHACL validation simply ends
    -- when inexpressible types are encountered. However, certain constructs such as lists can be validated using
    -- secondary structures. For example, see shsh:ListShape in the SHACL documentation. TODO: explore these constructions.
    any = pure $ common []

forObjects :: Rdf.Resource -> Rdf.Iri -> [Rdf.Node] -> [Rdf.Triple]
forObjects subj pred objs = (Rdf.Triple subj pred) <$> objs

iri :: String -> String -> Rdf.Iri
iri ns local = Rdf.Iri $ ns ++ local

keyIri :: String -> Rdf.Iri
keyIri = iri "urn:key:" -- Note: not an official URN scheme

mergeGraphs :: [Rdf.Graph] -> Rdf.Graph
mergeGraphs graphs = Rdf.Graph $ L.foldl S.union S.empty (Rdf.unGraph <$> graphs)

nameToIri :: Name -> Rdf.Iri
nameToIri = Rdf.Iri . unName

nextBlankNode :: Show m => GraphFlow m Rdf.BlankNode
nextBlankNode = do
  c <- getAttr nodeCount
  count <- case c of
    Nothing -> pure 0
    Just lit -> Literals.expectInt32 lit
  let node = Rdf.BlankNode $ "b" ++ show count
  putAttr nodeCount (Literals.int32 $ count + 1)
  return node

node :: [Shacl.CommonConstraint] -> Shacl.Shape
node = Shacl.ShapeNode . Shacl.NodeShape . common

property :: Rdf.Iri -> Shacl.PropertyShape
property iri = Shacl.PropertyShape {
  Shacl.propertyShapeCommon = defaultCommonProperties,
  Shacl.propertyShapeConstraints = S.empty,
  Shacl.propertyShapeDefaultValue = Nothing,
  Shacl.propertyShapeDescription = emptyLangStrings,
  Shacl.propertyShapeName = emptyLangStrings,
  Shacl.propertyShapeOrder = Nothing,
  Shacl.propertyShapePath = iri}

-- Note: these are not "proper" URNs, as they do not use an established URN scheme
propertyIri :: Name -> FieldName -> Rdf.Iri
propertyIri rname fname = Rdf.Iri $ "urn:" ++ unNamespace gname ++ "#" ++ decapitalize local ++ capitalize (unFieldName fname)
  where
    (gname, local) = toQname rname

rdfIri :: String -> Rdf.Iri
rdfIri = iri "http://www.w3.org/1999/02/22-rdf-syntax-ns#"

subjectsOf :: [Rdf.Description] -> [Rdf.Node]
subjectsOf descs = Rdf.descriptionSubject <$> descs

triplesOf :: [Rdf.Description] -> [Rdf.Triple]
triplesOf descs = L.concat ((S.toList . Rdf.unGraph . Rdf.descriptionGraph) <$> descs)

xmlSchemaDatatypeIri :: String -> Rdf.Iri
xmlSchemaDatatypeIri = iri "http://www.w3.org/2001/XMLSchema#"
