-- | Entry point for Hydra code generation utilities

module Hydra.Codegen (
  hydraKernel,
  kernelDataModules,
  kernelModelModules,
  kernelModules,
  langModules,
  mainModules,
  modulesToGraph,
  testModules,
  writeGraphql,
  writeHaskell,
  writeJava,
  writePdl,
  writeScala,
  writeYaml,
) where

import Hydra.Kernel
import Hydra.Dsl.Annotations
import qualified Hydra.Langs.Graphql.Coder as Graphql
import qualified Hydra.Langs.Haskell.Coder as Haskell
import qualified Hydra.Langs.Java.Coder as Java
import qualified Hydra.Langs.Json.Coder as Json
import qualified Hydra.Langs.Pegasus.Coder as PDL
import qualified Hydra.Langs.Scala.Coder as Scala
import qualified Hydra.Langs.Yaml.Modules as Yaml

import Hydra.Sources.Ast
import Hydra.Sources.Basics
import Hydra.Sources.Coders
import Hydra.Sources.Compute
import Hydra.Sources.Constraints
import Hydra.Sources.Core
import Hydra.Sources.Extras
import Hydra.Sources.Grammar
import Hydra.Sources.Graph
import Hydra.Sources.Langs.Avro.Schema
import Hydra.Sources.Langs.Graphql.Syntax
import Hydra.Sources.Langs.Haskell.Ast
import Hydra.Sources.Langs.Java.Syntax
import Hydra.Sources.Langs.Json.Model
import Hydra.Sources.Langs.Owl.Syntax
import Hydra.Sources.Langs.Parquet.Format
import Hydra.Sources.Langs.Pegasus.Pdl
import Hydra.Sources.Langs.Protobuf.Any
import Hydra.Sources.Langs.Protobuf.SourceContext
import Hydra.Sources.Langs.Protobuf.Type
import Hydra.Sources.Langs.Rdf.Syntax
import Hydra.Sources.Langs.RelationalModel
import Hydra.Sources.Langs.Scala.Meta
import Hydra.Sources.Langs.Shacl.Model
import Hydra.Sources.Langs.Shex.Syntax
import Hydra.Sources.Langs.Sql.Ansi
import Hydra.Sources.Langs.Tinkerpop.Features
import Hydra.Sources.Langs.Tinkerpop.Mappings
import Hydra.Sources.Langs.Tinkerpop.PropertyGraph
import Hydra.Sources.Langs.Xml.Schema
import Hydra.Sources.Langs.Yaml.Model
import Hydra.Sources.Libraries
import Hydra.Sources.Mantle
import Hydra.Sources.Module
import Hydra.Sources.Phantoms
import Hydra.Sources.Printing
import Hydra.Sources.Query
import Hydra.Sources.Test.TestSuite
import Hydra.Sources.Testing
import Hydra.Sources.Workflow

import qualified Control.Monad as CM
import qualified System.FilePath as FP
import qualified Data.List as L
import qualified Data.Map as M
import qualified System.Directory as SD
import qualified Data.Maybe as Y


findType :: Graph a -> Term a -> GraphFlow a (Maybe (Type a))
findType cx term = annotationClassTermType (graphAnnotations cx) term

generateSources :: (Module Kv -> GraphFlow Kv (M.Map FilePath String)) -> FilePath -> [Module Kv] -> IO ()
generateSources printModule basePath mods = do
    mfiles <- runFlow hydraKernel generateFiles
    case mfiles of
      Nothing -> fail "Transformation failed"
      Just files -> mapM_ writePair files
  where
    generateFiles = do
      withTrace "generate files" $ do
        withState (modulesToGraph mods) $ do
          g' <- inferGraphTypes
          withState g' $ do
              maps <- CM.mapM forModule $ refreshModule (graphElements g') <$> mods
              return $ L.concat (M.toList <$> maps)
            where
              refreshModule els mod = mod {
                moduleElements = Y.catMaybes ((\e -> M.lookup (elementName e) els) <$> moduleElements mod)}

    writePair (path, s) = do
      let fullPath = FP.combine basePath path
      SD.createDirectoryIfMissing True $ FP.takeDirectory fullPath
      writeFile fullPath s

    forModule mod = withTrace ("module " ++ unNamespace (moduleNamespace mod)) $ printModule mod

-- Note: currently a subset of the kernel, as the other modules are not yet needed in the runtime environment
hydraKernel :: Graph Kv
hydraKernel = elementsToGraph bootstrapGraph Nothing $ L.concatMap moduleElements [
  hydraComputeModule,
  hydraCoreModule,
  hydraGraphModule,
  hydraMantleModule,
  hydraModuleModule,
  hydraTestingModule]

kernelDataModules :: [Module Kv]
kernelDataModules = [
  hydraBasicsModule,
  hydraExtrasModule,
--  hydraMonadsModule,
  hydraPrintingModule]

kernelModelModules :: [Module Kv]
kernelModelModules = [
  hydraAstModule,
  hydraCodersModule,
  hydraCoreModule,
  hydraComputeModule,
  hydraConstraintsModule,
  hydraGrammarModule,
  hydraGraphModule,
  hydraMantleModule,
  hydraModuleModule,
  hydraPhantomsModule,
  hydraQueryModule,
  hydraTestingModule,
  hydraWorkflowModule,
  jsonModelModule] -- JSON module is part of the kernel, despite being an external language; JSON support is built in to Hydra

kernelModules :: [Module Kv]
kernelModules = kernelModelModules ++ kernelDataModules

langModules :: [Module Kv]
langModules = [
  avroSchemaModule,
  graphqlSyntaxModule,
  haskellAstModule,
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
  tinkerpopMappingsModule,
  tinkerpopPropertyGraphModule,
  xmlSchemaModule,
  yamlModelModule]

mainModules :: [Module Kv]
mainModules = kernelModules ++ langModules

modulesToGraph :: [Module Kv] -> Graph Kv
modulesToGraph mods = elementsToGraph hydraKernel (Just hydraKernel) elements
  where
    elements = L.concat (moduleElements <$> modules)
    modules = L.concat (close <$> mods)
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

testModules :: [Module Kv]
testModules = [
  testSuiteModule]

utilModules :: [Module Kv]
utilModules = [
  hydraPrintingModule,
  hydraBasicsModule,
  hydraExtrasModule]

writeGraphql :: FP.FilePath -> [Module Kv] -> IO ()
writeGraphql = generateSources Graphql.printModule

writeHaskell :: FilePath -> [Module Kv] -> IO ()
writeHaskell = generateSources Haskell.printModule

writeJava :: FP.FilePath -> [Module Kv] -> IO ()
writeJava = generateSources Java.printModule

-- writeJson :: FP.FilePath -> [Module Kv] -> IO ()
-- writeJson = generateSources Json.printModule

writePdl :: FP.FilePath -> [Module Kv] -> IO ()
writePdl = generateSources PDL.printModule

writeScala :: FP.FilePath -> [Module Kv] -> IO ()
writeScala = generateSources Scala.printModule

writeYaml :: FP.FilePath -> [Module Kv] -> IO ()
writeYaml = generateSources Yaml.printModule
