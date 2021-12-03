module Hydra.Prototyping.BasicsWithDslSpec where

import Hydra.Core
import Hydra.Evaluation
import Hydra.Impl.Haskell.Dsl.Terms
import Hydra.Impl.Haskell.Extras
import Hydra.Prototyping.Basics
import Hydra.Prototyping.BasicsWithDsl
import Hydra.Prototyping.Interpreter
import Hydra.Prototyping.Primitives
import Hydra.Prototyping.CoreEncoding
import Hydra.Prototyping.Rewriting

import Hydra.TestUtils

import qualified Test.Hspec as H
import qualified Test.QuickCheck as QC


testEvaluate :: Term Meta -> Result (Term Meta)
testEvaluate term = stripMeta <$> evaluate (testContext { contextElements = graphElementsMap (basicsGraph testContext) }) term

testsForTermTypeFunctions :: H.SpecWith a
testsForTermTypeFunctions = do
  H.describe "Tests for DSL-defined term-to-type functions" $ do
    return ()
--    literalType,
--    floatValueType,
--    integerValueType,

testsForTermVariantFunctions :: H.SpecWith a
testsForTermVariantFunctions = do
  H.describe "Tests for DSL-defined term-to-variant functions" $ do
    return ()
--    literalVariant,
--    floatValueVariant,
--    integerValueVariant,
--    termVariant

testsForTypeVariantFunctions :: H.SpecWith ()
testsForTypeVariantFunctions = do
  H.describe "Tests for DSL-defined type-to-variant functions" $ do

    H.it "Test literalTypeVariant function element" $
      QC.property $ \at ->
        testEvaluate (apply (elementRefByName "hydra/basics.literalTypeVariant") (encodeLiteralType testContext at))
        `H.shouldBe`
        pure (stripMeta $ encodeLiteralVariant testContext $ literalTypeVariant at)

    H.it "Test floatTypeVariant function element" $
      QC.property $ \ft ->
        testEvaluate (apply (elementRefByName "hydra/basics.floatTypeVariant") (encodeFloatType testContext ft))
        `H.shouldBe`
        pure (stripMeta $ encodeFloatVariant testContext $ floatTypeVariant ft)

    H.it "Test integerTypeVariant function element" $
      QC.property $ \at ->
        testEvaluate (apply (elementRefByName "hydra/basics.integerTypeVariant") (encodeIntegerType testContext at))
        `H.shouldBe`
        pure (stripMeta $ encodeIntegerVariant testContext $ integerTypeVariant at)

    H.it "Test typeVariant function element" $
      QC.property $ \t ->
        testEvaluate (apply (elementRefByName "hydra/basics.typeVariant") (encodeType testContext t))
        `H.shouldBe`
        pure (stripMeta $ encodeTypeVariant testContext $ typeVariant t)

spec :: H.Spec
spec = do
  testsForTermTypeFunctions
  testsForTermVariantFunctions
  testsForTypeVariantFunctions
