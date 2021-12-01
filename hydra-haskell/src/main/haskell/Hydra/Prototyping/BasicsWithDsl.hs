module Hydra.Prototyping.BasicsWithDsl (
  basicsGraph,
) where

import Hydra.Core
import Hydra.Evaluation
import Hydra.Graph
import Hydra.Prototyping.CoreEncoding
import Hydra.Impl.Haskell.Dsl.Terms


basicsElement :: Context Meta -> String -> Type -> Term Meta -> Element Meta
basicsElement cx name typ = Element ("hydra/basics." ++ name) (encodeType cx typ)

basicsFunction :: Context Meta -> String -> Name -> Name -> Term Meta -> Element Meta
basicsFunction cx name dom cod = basicsElement cx name typ
  where
    typ = functionType (nominalType dom) (nominalType cod)

basicsGraph :: Context Meta -> Graph Meta
basicsGraph cx = Graph "hydra/basics" elements dataTerms schemaGraph
  where
    dataTerms = const True -- TODO
    schemaGraph = "hydra/core"
    elements = (\f -> f cx) <$> [
        basicsFloatTypeVariant,
        basicsFloatValueType,
        basicsFloatValueVariant,
        basicsFunctionVariant,
        basicsIntegerTypeVariant,
        basicsIntegerValueType,
        basicsIntegerValueVariant,
        basicsLiteralTypeVariant,
        basicsLiteralType,
        basicsLiteralVariant,
        basicsTermVariant,
        basicsTypeVariant]

basicsFloatTypeVariant :: Context Meta -> Element Meta
basicsFloatTypeVariant cx = basicsFunction cx "floatTypeVariant" _FloatType _FloatVariant $
  matchWithVariants _FloatVariant [
    (_FloatType_bigfloat, _FloatVariant_bigfloat),
    (_FloatType_float32,  _FloatVariant_float32),
    (_FloatType_float64,  _FloatVariant_float64)]

basicsFloatValueType :: Context Meta -> Element Meta
basicsFloatValueType cx = basicsFunction cx "floatValueType" _FloatValue _FloatType $
  matchWithVariants _FloatType [
    (_FloatValue_bigfloat, _FloatType_bigfloat),
    (_FloatValue_float32,  _FloatType_float32),
    (_FloatValue_float64,  _FloatType_float64)]

basicsFloatValueVariant :: Context Meta -> Element Meta
basicsFloatValueVariant cx = basicsFunction cx "floatValueVariant" _FloatValue _FloatVariant $
  compose (elementRef $ basicsFloatTypeVariant cx) (elementRef $ basicsFloatValueType cx)

basicsIntegerTypeVariant :: Context Meta -> Element Meta
basicsIntegerTypeVariant cx = basicsFunction cx "integerTypeVariant" _IntegerType _IntegerVariant $
  matchWithVariants _IntegerVariant [
    (_IntegerType_bigint, _IntegerVariant_bigint),
    (_IntegerType_int8,   _IntegerVariant_int8),
    (_IntegerType_int16,  _IntegerVariant_int16),
    (_IntegerType_int32,  _IntegerVariant_int32),
    (_IntegerType_int64,  _IntegerVariant_int64),
    (_IntegerType_uint8,  _IntegerVariant_uint8),
    (_IntegerType_uint16, _IntegerVariant_uint16),
    (_IntegerType_uint32, _IntegerVariant_uint32),
    (_IntegerType_uint64, _IntegerVariant_uint64)]

basicsIntegerValueType :: Context Meta -> Element Meta
basicsIntegerValueType cx = basicsFunction cx "integerValueType"_IntegerValue _IntegerType $
  matchWithVariants _IntegerValue [
    (_IntegerValue_bigint, _IntegerValue_bigint),
    (_IntegerValue_int8,   _IntegerValue_int8),
    (_IntegerValue_int16,  _IntegerValue_int16),
    (_IntegerValue_int32,  _IntegerValue_int32),
    (_IntegerValue_int64,  _IntegerValue_int64),
    (_IntegerValue_uint8,  _IntegerValue_uint8),
    (_IntegerValue_uint16, _IntegerValue_uint16),
    (_IntegerValue_uint32, _IntegerValue_uint32),
    (_IntegerValue_uint64, _IntegerValue_uint64)]

basicsIntegerValueVariant :: Context Meta -> Element Meta
basicsIntegerValueVariant cx = basicsFunction cx "integerValueVariant" _IntegerValue _IntegerVariant $
  compose (elementRef $ basicsIntegerTypeVariant cx) (elementRef $ basicsIntegerValueType cx)

basicsFunctionVariant :: Context Meta -> Element Meta
basicsFunctionVariant cx = basicsFunction cx "functionVariant" _Function _FunctionVariant $
  matchWithVariants _FunctionVariant [
    (_Function_cases,      _FunctionVariant_cases),
    (_Function_compareTo,  _FunctionVariant_compareTo),
    (_Function_data,       _FunctionVariant_data),
    (_Function_lambda,     _FunctionVariant_lambda),
    (_Function_primitive,  _FunctionVariant_primitive),
    (_Function_projection, _FunctionVariant_projection)]

basicsLiteralTypeVariant :: Context Meta -> Element Meta
basicsLiteralTypeVariant cx = basicsFunction cx "literalTypeVariant" _LiteralType _LiteralVariant $
  matchWithVariants _LiteralVariant [
    (_LiteralType_binary,  _LiteralVariant_binary),
    (_LiteralType_boolean, _LiteralVariant_boolean),
    (_LiteralType_float,   _LiteralVariant_float),
    (_LiteralType_integer, _LiteralVariant_integer),
    (_LiteralType_string,  _LiteralVariant_string)]

basicsLiteralType :: Context Meta -> Element Meta
basicsLiteralType cx = basicsFunction cx "literalType" _Literal _LiteralType $
  match [
    (_Literal_binary,  withVariant  _LiteralType _LiteralType_binary),
    (_Literal_boolean, withVariant  _LiteralType _LiteralType_boolean),
    (_Literal_float,   withFunction _LiteralType _LiteralType_float (basicsFloatValueType cx)),
    (_Literal_integer, withFunction _LiteralType _LiteralType_integer (basicsIntegerValueType cx)),
    (_Literal_string,  withVariant  _LiteralType _LiteralType_string)]

basicsLiteralVariant :: Context Meta -> Element Meta
basicsLiteralVariant cx = basicsFunction cx "literalVariant" _Literal _LiteralVariant $
  compose (elementRef $ basicsLiteralTypeVariant cx) (elementRef $ basicsLiteralType cx)

basicsTermVariant :: Context Meta -> Element Meta
basicsTermVariant cx = basicsFunction cx "termVariant" _Term _TermVariant $
  matchWithVariants _Expression [
    (_Expression_element,         _TermVariant_element),
    (_Expression_function,        _TermVariant_function),
    (_Expression_list,            _TermVariant_list),
    (_Expression_literal,         _TermVariant_literal),
    (_Expression_map,             _TermVariant_map),
    (_Expression_nominal,         _TermVariant_nominal),
    (_Expression_optional,        _TermVariant_optional),
    (_Expression_record,          _TermVariant_record),
    (_Expression_set,             _TermVariant_set),
    (_Expression_typeAbstraction, _TermVariant_typeAbstraction),
    (_Expression_typeApplication, _TermVariant_typeApplication),
    (_Expression_union,           _TermVariant_union),
    (_Expression_variable,        _TermVariant_variable)]

basicsTypeVariant :: Context Meta -> Element Meta
basicsTypeVariant cx = basicsFunction cx "typeVariant" _Type _TypeVariant $
  matchWithVariants _TypeVariant [
    (_Type_element,   _TypeVariant_element),
    (_Type_function,  _TypeVariant_function),
    (_Type_list,      _TypeVariant_list),
    (_Type_literal,   _TypeVariant_literal),
    (_Type_map,       _TypeVariant_map),
    (_Type_nominal,   _TypeVariant_nominal),
    (_Type_optional,  _TypeVariant_optional),
    (_Type_record,    _TypeVariant_record),
    (_Type_set,       _TypeVariant_set),
    (_Type_union,     _TypeVariant_union),
    (_Type_universal, _TypeVariant_universal),
    (_Type_variable,  _TypeVariant_variable)]
