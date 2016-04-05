{-# LANGUAGE OverloadedStrings #-}
module Parse where

import Data.Attoparsec.ByteString (Parser, IResult(..), satisfy, anyWord8, take, parseWith)
import Data.Bits                  ((.|.), shiftL)
import Data.ByteString            (ByteString)
import Data.IORef
import Data.Maybe                 (fromMaybe)
import Data.Monoid                ((<>))
import Data.Word                  (Word8)
import Network.Simple.TCP         (Socket, recv)
import Prelude hiding             (take)

import Types

handshakeByteToType :: Word8 -> HandshakeType
handshakeByteToType 0  = NoiseNN
handshakeByteToType 1  = NoiseKN
handshakeByteToType 2  = NoiseNK
handshakeByteToType 3  = NoiseKK
handshakeByteToType 4  = NoiseNX
handshakeByteToType 5  = NoiseKX
handshakeByteToType 6  = NoiseXN
handshakeByteToType 7  = NoiseIN
handshakeByteToType 8  = NoiseXK
handshakeByteToType 9  = NoiseIK
handshakeByteToType 10 = NoiseXX
handshakeByteToType 11 = NoiseIX
handshakeByteToType 12 = NoiseXR
handshakeByteToType _  = error "invalid handshake type"

cipherByteToType :: Word8 -> SomeCipherType
cipherByteToType 0 = WrapCipherType CTChaChaPoly1305
cipherByteToType 1 = WrapCipherType CTAESGCM
cipherByteToType _ = error "invalid cipher type"

curveByteToType :: Word8 -> SomeCurveType
curveByteToType 0 = WrapCurveType CTCurve25519
curveByteToType 1 = WrapCurveType CTCurve448
curveByteToType _ = error "invalid curve type"

hashByteToType :: Word8 -> SomeHashType
hashByteToType 0 = WrapHashType HTSHA256
hashByteToType 1 = WrapHashType HTSHA512
hashByteToType 2 = WrapHashType HTBLAKE2s
hashByteToType 3 = WrapHashType HTBLAKE2b
hashByteToType _ = error "invalid hash type"

headerParser :: Parser Header
headerParser = do
  hsb <- satisfy (< 13)
  cib <- satisfy (< 2)
  cub <- satisfy (< 2)
  hb  <- satisfy (< 4)

  return (handshakeByteToType hsb, cipherByteToType cib, curveByteToType cub, hashByteToType hb)

messageParser :: Parser ByteString
messageParser = do
  l0 <- fromIntegral <$> anyWord8
  l1 <- fromIntegral <$> anyWord8
  take (l0 `shiftL` 8 .|. l1)

parseSocket :: IORef ByteString -> Socket -> Parser a -> IO (Maybe a)
parseSocket bufRef sock p = do
  buf <- readIORef bufRef
  result <- parseWith (fromMaybe "" <$> recv sock 2048) p buf
  case result of
    Fail{} -> return Nothing
    (Partial _)  -> return Nothing
    (Done i r)   -> modifyIORef' bufRef (<> i) >> return (Just r)