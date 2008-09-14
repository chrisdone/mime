--------------------------------------------------------------------
-- |
-- Module    : Codec.MIME.QuotedPrintable
-- Copyright : (c) Galois, Inc. 2008
-- License   : BSD3
--
-- Maintainer: 
-- Stability : provisional
-- Portability:
--
--------------------------------------------------------------------


module Codec.MIME.QuotedPrintable 
       ( decode -- :: String -> String
       , encode -- :: String -> String
       ) where

import Data.Char

-- | 'decode' incoming quoted-printable content, stripping
-- out soft line breaks and 
decode :: String -> String
decode "" = ""
decode ('=':'\r':'\n':xs) = decode xs -- soft line break.
decode ('=':x1:x2:xs)
 | isHexDigit x1 && isHexDigit x2 =
    chr (digitToInt x1 * 16 + digitToInt x2) : decode xs
decode ('=':xs) = '=':decode xs
              -- make it explicit that we propagate other '=' occurrences.
decode (x1:xs) = x1:decode xs

-- | 'encode' converts a sequence of characeter _octets_ into
-- quoted-printable form; suitable for transmission in MIME
-- payloads. Note the stress on _octets_; it is assumed that
-- you have already converted Unicode into a <=8-bit encoding
-- (UTF-8, most likely.)
encode :: String -> String
encode xs = encodeLength 0 xs

encodeLength :: Int -> String -> String
encodeLength _ "" = ""
encodeLength n (x:xs)
 | n >= 72  = '=':'\r':'\n':encodeLength 0 (x:xs)
encodeLength n ('=':xs) 
 = '=':'3':'D':encodeLength 0 xs
encodeLength n (x:xs)
 | ox >= 0x100 = error ("QuotedPrintable.encode: encountered > 8 bit character: " ++ show (x,ox))
 | n >= 72     = '=':'\r':'\n':encodeLength 0 (x:xs)
 | ox >= 0x21 && ox <= 0x7e = x : encodeLength (n+1) xs
 | ox == 0x09 || ox == 0x20 = x : encodeLength (n+1) xs
 | otherwise = '=':'\r':'\n':encodeLength 0 (x:xs)
 where
  ox = ord x
  showH v
   | v < 10    = chr (ord_0 + v)
   | otherwise = chr (ord_A + (v-10))
   
  ord_0 = ord '0'
  ord_A = ord 'A'
