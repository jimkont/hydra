-- | A DSL for constructing Hydra types

module Hydra.Dsl.Types where

import Hydra.Common
import Hydra.Core
import Hydra.Lexical
import Hydra.Monads

import qualified Data.List as L
import qualified Data.Map as M
import Data.String(IsString(..))


instance IsString (Type m) where fromString = variable

infixr 0 >:
(>:) :: String -> Type m -> FieldType m
n >: t = field n t

infixr 0 -->
(-->) :: Type m -> Type m -> Type m
a --> b = function a b

(@@) :: Type m -> Type m -> Type m
f @@ x = apply f x

annot :: m -> Type m -> Type m
annot ann t = TypeAnnotated $ Annotated t ann

apply :: Type m -> Type m -> Type m
apply lhs rhs = TypeApplication (ApplicationType lhs rhs)

bigfloat :: Type m
bigfloat = float FloatTypeBigfloat

bigint :: Type m
bigint = integer IntegerTypeBigint

binary :: Type m
binary = literal LiteralTypeBinary

boolean :: Type m
boolean = literal LiteralTypeBoolean

element :: Type m -> Type m
element = TypeElement

enum :: [String] -> Type m
enum names = union $ (`field` unit) <$> names

field :: String -> Type m -> FieldType m
field fn = FieldType (FieldName fn)

fieldsToMap :: [FieldType m] -> M.Map FieldName (Type m)
fieldsToMap fields = M.fromList $ (\(FieldType name typ) -> (name, typ)) <$> fields

float32 :: Type m
float32 = float FloatTypeFloat32

float64 :: Type m
float64 = float FloatTypeFloat64

float :: FloatType -> Type m
float = literal . LiteralTypeFloat

function :: Type m -> Type m -> Type m
function dom cod = TypeFunction $ FunctionType dom cod

functionN :: [Type m] -> Type m -> Type m
functionN doms cod = if L.null doms
  then cod
  else function (L.head doms) $ functionN (L.tail doms) cod

int16 :: Type m
int16 = integer IntegerTypeInt16

int32 :: Type m
int32 = integer IntegerTypeInt32

int64 :: Type m
int64 = integer IntegerTypeInt64

int8 :: Type m
int8 = integer IntegerTypeInt8

integer :: IntegerType -> Type m
integer = literal . LiteralTypeInteger

lambda :: String -> Type m -> Type m
lambda v body = TypeLambda $ LambdaType (Name v) body

list :: Type m -> Type m
list = TypeList

isUnit :: Eq m => Type m -> Bool
isUnit t = stripType t == TypeRecord (RowType unitTypeName Nothing [])

literal :: LiteralType -> Type m
literal = TypeLiteral

map :: Type m -> Type m -> Type m
map kt vt = TypeMap $ MapType kt vt

optional :: Type m -> Type m
optional = TypeOptional

product :: [Type m] -> Type m
product = TypeProduct

record :: [FieldType m] -> Type m
record fields = TypeRecord $ RowType placeholderName Nothing fields

set :: Type m -> Type m
set = TypeSet

string :: Type m
string = literal LiteralTypeString

sum :: [Type m] -> Type m
sum = TypeSum

uint16 :: Type m
uint16 = integer IntegerTypeUint16

uint32 :: Type m
uint32 = integer IntegerTypeUint32

uint64 :: Type m
uint64 = integer IntegerTypeUint64

uint8 :: Type m
uint8 = integer IntegerTypeUint8

union :: [FieldType m] -> Type m
union fields = TypeUnion $ RowType placeholderName Nothing fields

unit :: Type m
unit = TypeRecord $ RowType (Name "hydra/core.UnitType") Nothing []

variable :: String -> Type m
variable = TypeVariable . Name

wrap :: Name -> Type m
wrap = TypeWrap
