-- | Haskell implementations of hydra/lib/literals primitives

module Hydra.Lib.Literals where

import Data.Int


bigfloatToBigint :: Double -> Integer
bigfloatToBigint = round

bigfloatToFloat32 :: Double -> Float
bigfloatToFloat32 = realToFrac

bigfloatToFloat64 :: Double -> Double
bigfloatToFloat64 = id

bigintToBigfloat :: Integer -> Double
bigintToBigfloat = fromIntegral

bigintToInt8 :: Integer -> Int8
bigintToInt8 = fromIntegral

bigintToInt16 :: Integer -> Int16
bigintToInt16 = fromIntegral

bigintToInt32 :: Integer -> Int
bigintToInt32 = fromIntegral

bigintToInt64 :: Integer -> Int64
bigintToInt64 = fromIntegral

bigintToUint8 :: Integer -> Int16
bigintToUint8 = fromIntegral

bigintToUint16 :: Integer -> Int
bigintToUint16 = fromIntegral

bigintToUint32 :: Integer -> Int64
bigintToUint32 = fromIntegral

bigintToUint64 :: Integer -> Integer
bigintToUint64 = id

float32ToBigfloat :: Float -> Double
float32ToBigfloat = realToFrac

float64ToBigfloat :: Double -> Double
float64ToBigfloat = id

int8ToBigint :: Int8 -> Integer
int8ToBigint = fromIntegral

int16ToBigint :: Int16 -> Integer
int16ToBigint = fromIntegral

int32ToBigint :: Int -> Integer
int32ToBigint = fromIntegral

int64ToBigint :: Int64 -> Integer
int64ToBigint = fromIntegral

showInt32 :: Int -> String
showInt32 = show

showString :: String -> String
showString = show

uint8ToBigint :: Int16 -> Integer
uint8ToBigint = fromIntegral

uint16ToBigint :: Int -> Integer
uint16ToBigint = fromIntegral

uint32ToBigint :: Int64 -> Integer
uint32ToBigint = fromIntegral

uint64ToBigint :: Integer -> Integer
uint64ToBigint = id
