{-# LANGUAGE OverloadedStrings #-}

module Hydra.Sources.Mantle where

import Hydra.Kernel
import Hydra.Dsl.Types as Types
import Hydra.Dsl.Standard
import Hydra.Sources.Core


hydraMantleModule :: Module Kv
hydraMantleModule = Module ns elements [] $
    Just "A set of types which supplement hydra/core with type variants, graphs, and elements"
  where
    ns = Namespace "hydra/mantle"
    core = nsref $ moduleNamespace hydraCoreModule
    mantle = nsref ns
    def = datatype ns

    elements = [

      def "Comparison" $
        doc "An equality judgement: less than, equal to, or greater than" $
        enum [
          "lessThan",
          "equalTo",
          "greaterThan"],

      def "Element" $
        doc "A graph element, having a name, data term (value), and schema term (type)" $
        lambda "m" $ record [
          "name">: core "Name",
          "schema">: core "Term" @@ "m",
          "data">: core "Term" @@ "m"],

      def "EliminationVariant" $
        doc "The identifier of an elimination constructor" $
        enum [
          "element",
          "list",
          "optional",
          "record",
          "union",
          "wrap"],

      def "FunctionVariant" $
        doc "The identifier of a function constructor" $
        enum [
          "elimination",
          "lambda",
          "primitive"],

      def "Graph" $
        doc ("A graph, or set of named terms, together with its schema graph") $
        lambda "m" $ record [
          "elements">:
            doc "All of the elements in the graph" $
            Types.map (core "Name") (mantle "Element" @@ "m"),
          "schema">:
            doc "The schema graph to this graph. If omitted, the graph is its own schema graph." $
            optional $ mantle "Graph" @@ "m"],

      def "LiteralVariant" $
        doc "The identifier of a literal constructor" $
        enum [
          "binary",
          "boolean",
          "float",
          "integer",
          "string"],

      def "Precision" $
        doc "Numeric precision: arbitrary precision, or precision to a specified number of bits" $
        union [
          "arbitrary">: unit,
          "bits">: int32],

      def "TermVariant" $
        doc "The identifier of a term expression constructor" $
        enum [
          "annotated",
          "application",
          "element",
          "function",
          "let",
          "list",
          "literal",
          "map",
          "optional",
          "product",
          "record",
          "set",
          "stream",
          "sum",
          "union",
          "variable",
          "wrap"],

      def "TypeScheme" $
        doc "A type expression together with free type variables occurring in the expression" $
        lambda "m" $ record [
          "variables">: list $ core "Name",
          "type">: core "Type" @@ "m"],

      def "TypeVariant" $
        doc "The identifier of a type constructor" $
        enum [
          "annotated",
          "application",
          "element",
          "function",
          "lambda",
          "list",
          "literal",
          "map",
          "optional",
          "product",
          "record",
          "set",
          "stream",
          "sum",
          "union",
          "variable",
          "wrap"],

      def "TypedTerm" $
        doc "A type together with an instance of the type" $
        lambda "m" $ record [
          "type">: core "Type" @@ "m",
          "term">: core "Term" @@ "m"]]
