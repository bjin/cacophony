{-# LANGUAGE TypeFamilies #-}

----------------------------------------------------------------
-- |
-- Module      : Crypto.Noise.Curve
-- Maintainer  : John Galt <centromere@users.noreply.github.com>
-- Stability   : experimental
-- Portability : POSIX

module Crypto.Noise.Curve
  ( -- * Classes
    Curve(..),
    -- * Types
    KeyPair
  ) where

import Data.ByteArray (ScrubbedBytes)
import Data.ByteString (ByteString)

class Curve c where
  data PublicKey c :: *
  data SecretKey c :: *

  curveName       :: c -> ScrubbedBytes
  curveLen        :: c -> Int
  curveGenKey     :: IO (KeyPair c)
  curveDH         :: SecretKey c -> PublicKey c -> ScrubbedBytes
  curveKeyBytes   :: KeyPair c -> (ScrubbedBytes, ByteString)
  curveBytesToPub :: ScrubbedBytes -> PublicKey c

type KeyPair c = (SecretKey c, PublicKey c)