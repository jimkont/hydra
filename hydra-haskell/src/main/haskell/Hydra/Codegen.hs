-- | Entry point for Hydra code generation utilities

module Hydra.Codegen where

import Hydra.Kernel
import Hydra.Dsl.Annotations
import qualified Hydra.Ext.Haskell.Coder as Haskell
import qualified Hydra.Ext.Java.Coder as Java
import qualified Hydra.Ext.Pegasus.Coder as PDL
import qualified Hydra.Ext.Scala.Coder as Scala
import qualified Hydra.Ext.Yaml.Modules as Yaml

import Hydra.Sources.Adapters.Utils
import Hydra.Sources.Basics
import Hydra.Sources.Compute
import Hydra.Sources.Core
import Hydra.Sources.Ext.Avro.Schema
import Hydra.Sources.Ext.Graphql.Syntax
import Hydra.Sources.Ext.Haskell.Ast
import Hydra.Sources.Ext.Java.Syntax
import Hydra.Sources.Ext.Json.Model
import Hydra.Sources.Ext.Owl.Syntax
import Hydra.Sources.Ext.Parquet.Format
import Hydra.Sources.Ext.Pegasus.Pdl
import Hydra.Sources.Ext.Protobuf.Any
import Hydra.Sources.Ext.Protobuf.SourceContext
import Hydra.Sources.Ext.Protobuf.Type
import Hydra.Sources.Ext.Rdf.Syntax
import Hydra.Sources.Ext.RelationalModel
import Hydra.Sources.Ext.Scala.Meta
import Hydra.Sources.Ext.Shacl.Model
import Hydra.Sources.Ext.Shex.Syntax
import Hydra.Sources.Ext.Sql.Ansi
import Hydra.Sources.Ext.Tinkerpop.Features
import Hydra.Sources.Ext.Tinkerpop.Typed
import Hydra.Sources.Ext.Tinkerpop.V3
import Hydra.Sources.Ext.Xml.Schema
import Hydra.Sources.Ext.Yaml.Model
import Hydra.Sources.Grammar
import Hydra.Sources.Libraries
import Hydra.Sources.Coders
import Hydra.Sources.Graph
import Hydra.Sources.Mantle
import Hydra.Sources.Module
import Hydra.Sources.Workflow
import Hydra.Sources.Phantoms
import Hydra.Sources.Util.Codetree.Ast

import qualified Control.Monad as CM
import qualified System.FilePath as FP
import qualified Data.List as L
import qualified Data.Map as M
import qualified System.Directory as SD
import qualified Data.Maybe as Y


addDeepTypeAnnotations :: (Ord m, Show m) => Module m -> GraphFlow m (Module m)
addDeepTypeAnnotations mod = do
    els <- CM.mapM annotateElementWithTypes $ moduleElements mod
    return $ mod {moduleElements = els}

allModules :: [Module Kv]
allModules = coreModules ++ utilModules ++ extModules

assignSchemas :: (Ord m, Show m) => Bool -> Module m -> GraphFlow m (Module m)
assignSchemas doInfer mod = do
    cx <- getState
    els <- CM.mapM (annotate cx) $ moduleElements mod
    return $ mod {moduleElements = els}
  where
    annotate cx el = do
      typ <- findType cx (elementData el)
      case typ of
        Nothing -> if doInfer
          then do
            t <- typeSchemeType <$> inferType (elementData el)
            return el {elementSchema = epsilonEncodeType t}
          else return el
        Just typ -> return el {elementSchema = epsilonEncodeType typ}

coreModules :: [Module Kv]
coreModules = [
  codetreeAstModule,
  haskellAstModule,
  hydraCodersModule,
  hydraCoreModule,
  hydraComputeModule,
  hydraGraphModule,
  hydraMantleModule,
  hydraModuleModule,
  hydraGrammarModule,
  hydraWorkflowModule,
--  hydraMonadsModule,
  hydraPhantomsModule,
  jsonModelModule]

utilModules = [
  adapterUtilsModule,
  hydraBasicsModule]

extModules :: [Module Kv]
extModules = [
  avroSchemaModule,
  graphqlSyntaxModule,
  javaSyntaxModule,
  owlSyntaxModule,
  parquetFormatModule,
  pegasusPdlModule,
  protobufAnyModule,
  protobufSourceContextModule,
  protobufTypeModule,
  rdfSyntaxModule,
  relationalModelModule,
  scalaMetaModule,
  shaclModelModule,
  shexSyntaxModule,
  sqlModule,
  tinkerpopFeaturesModule,
  tinkerpopTypedModule,
  tinkerpopV3Module,
  xmlSchemaModule,
  yamlModelModule]

findType :: Graph m -> Term m -> GraphFlow m (Maybe (Type m))
findType cx term = annotationClassTermType (graphAnnotations cx) term

generateSources :: (Module Kv -> GraphFlow Kv (M.Map FilePath String)) -> [Module Kv] -> FilePath -> IO ()
generateSources printModule mods0 basePath = do
    mfiles <- runFlow hydraKernel generateFiles
    case mfiles of
      Nothing -> fail "Transformation failed"
      Just files -> mapM_ writePair files
  where
    generateFiles = do
      withTrace "generate files" $ do
        mods1 <- CM.mapM (assignSchemas False) mods0
        withState (modulesToGraph mods1) $ do
          mods2 <- CM.mapM addDeepTypeAnnotations mods1
          maps <- CM.mapM printModule mods2
          return $ L.concat (M.toList <$> maps)

    writePair (path, s) = do
      let fullPath = FP.combine basePath path
      SD.createDirectoryIfMissing True $ FP.takeDirectory fullPath
      writeFile fullPath s

hydraKernel :: Graph Kv
hydraKernel = elementsToGraph bootstrapGraph Nothing $ L.concatMap moduleElements [hydraCoreModule, hydraMantleModule, hydraModuleModule]

modulesToGraph :: [Module Kv] -> Graph Kv
modulesToGraph mods = elementsToGraph hydraKernel (Just hydraKernel) elements
  where
    elements = L.concat (moduleElements <$> allModules)
    allModules = L.concat (close <$> mods)
      where
        close mod = mod:(L.concat (close <$> moduleDependencies mod))

printTrace :: Bool -> Trace -> IO ()
printTrace isError t = do
  CM.unless (L.null $ traceMessages t) $ do
      putStrLn $ if isError then "Flow failed. Messages:" else "Messages:"
      putStrLn $ indentLines $ traceSummary t

runFlow :: s -> Flow s a -> IO (Maybe a)
runFlow cx f = do
  let FlowState v _ t = unFlow f cx emptyTrace
  printTrace (Y.isNothing v) t
  return v

writeHaskell :: [Module Kv] -> FilePath -> IO ()
writeHaskell = generateSources Haskell.printModule

writeJava :: [Module Kv] -> FP.FilePath -> IO ()
writeJava = generateSources Java.printModule

writePdl :: [Module Kv] -> FP.FilePath -> IO ()
writePdl = generateSources PDL.printModule

writeScala :: [Module Kv] -> FP.FilePath -> IO ()
writeScala = generateSources Scala.printModule

writeYaml :: [Module Kv] -> FP.FilePath -> IO ()
writeYaml = generateSources Yaml.printModule
