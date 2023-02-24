module Hydra.Dsl.Lib.Strings where

import Hydra.Phantoms
import qualified Hydra.Dsl.Terms as Terms
import Hydra.Sources.Libraries


cat :: Datum ([String] -> String)
cat = Datum $ Terms.primitive _strings_cat

length :: Datum (String -> Int)
length = Datum $ Terms.primitive _strings_length

splitOn :: Datum (String -> String -> [String])
splitOn = Datum $ Terms.primitive _strings_splitOn

toLower :: Datum (String -> String)
toLower = Datum $ Terms.primitive _strings_toLower

toUpper :: Datum (String -> String)
toUpper = Datum $ Terms.primitive _strings_toUpper