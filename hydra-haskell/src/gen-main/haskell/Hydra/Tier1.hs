-- | A module for all tier-1 functions and constants. These are generated functions and constants which DSL functions and the implementations of primitive functions are allowed to depend upon. Higher tiers of generated code may not be depended upon, as these tiers may themselves need to depend on DSL functions or primitive functions.

module Hydra.Tier1 where

import qualified Hydra.Core as Core
import qualified Hydra.Lib.Strings as Strings
import qualified Hydra.Module as Module
import Data.Int
import Data.List
import Data.Map
import Data.Set

ignoredVariable :: String
ignoredVariable = "_"

-- | A placeholder name for row types as they are being constructed
placeholderName :: Core.Name
placeholderName = (Core.Name "Placeholder")

skipAnnotations :: ((x -> Maybe (Core.Annotated x a)) -> x -> x)
skipAnnotations getAnn t =  
  let skip = (\t1 -> (\x -> case x of
          Nothing -> t1
          Just v -> (skip (Core.annotatedSubject v))) (getAnn t1))
  in (skip t)

-- | Strip all annotations from a term
stripTerm :: (Core.Term a -> Core.Term a)
stripTerm x = (skipAnnotations (\x -> case x of
  Core.TermAnnotated v -> (Just v)
  _ -> Nothing) x)

-- | Strip all annotations from a type
stripType :: (Core.Type a -> Core.Type a)
stripType x = (skipAnnotations (\x -> case x of
  Core.TypeAnnotated v -> (Just v)
  _ -> Nothing) x)

-- | Convert a qualified name to a dot-separated name
unqualifyName :: (Module.QualifiedName -> Core.Name)
unqualifyName qname =  
  let prefix = ((\x -> case x of
          Nothing -> ""
          Just v -> (Strings.cat [
            Module.unNamespace v,
            "."])) (Module.qualifiedNameNamespace qname))
  in (Core.Name (Strings.cat [
    prefix,
    (Module.qualifiedNameLocal qname)]))