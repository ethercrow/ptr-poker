module PtrPoker.Write
where

import PtrPoker.Prelude
import qualified PtrPoker.IO.ByteString as ByteStringIO
import qualified PtrPoker.IO.Prim as PrimIO
import qualified PtrPoker.Poke as Poke
import qualified PtrPoker.Size as Size
import qualified PtrPoker.Ffi as Ffi
import qualified PtrPoker.ByteString as ByteString
import qualified Data.ByteString as ByteString
import qualified Data.ByteString.Internal as ByteString


{-|
Execute Write, producing strict ByteString.
-}
{-# INLINABLE writeToByteString #-}
writeToByteString :: Write -> ByteString
writeToByteString Write{..} =
  ByteString.unsafeCreate writeSize (void . Poke.pokePtr writePoke)

{-|
Specification of how many bytes to allocate and how to populate them.

Useful for creating strict bytestrings and tasks like that.
-}
data Write =
  Write {
    writeSize :: Int,
    writePoke :: Poke.Poke
    }

instance Semigroup Write where
  {-# INLINE (<>) #-}
  Write lSize lPoke <> Write rSize rPoke =
    Write (lSize + rSize) (lPoke <> rPoke)

instance Monoid Write where
  {-# INLINE mempty #-}
  mempty =
    Write 0 mempty

{-|
Reuses the IsString instance of 'ByteString'.
-}
instance IsString Write where
  {-# INLINE fromString #-}
  fromString =
    byteString . fromString

{-|
Render Word8 as byte.
-}
{-# INLINE word8 #-}
word8 :: Word8 -> Write
word8 a =
  Write 1 (Poke.word8 a)

{-|
Render Word64 in ASCII decimal.
-}
{-# INLINE word64AsciiDec #-}
word64AsciiDec :: Word64 -> Write
word64AsciiDec a =
  Write size poke
  where
    size =
      Size.word64AsciiDec a
    poke =
      Poke.sizedReverse size (Ffi.revPokeUInt64 (fromIntegral a))

{-|
Render Word in ASCII decimal.
-}
{-# INLINE wordAsciiDec #-}
wordAsciiDec :: Word -> Write
wordAsciiDec =
  word64AsciiDec . fromIntegral

{-|
Render Int64 in ASCII decimal.
-}
{-# INLINE int64AsciiDec #-}
int64AsciiDec :: Int64 -> Write
int64AsciiDec a =
  Write size poke
  where
    size =
      Size.int64AsciiDec a
    poke =
      Poke.sizedReverse size (Ffi.revPokeInt64 (fromIntegral a))

{-|
Render Int in ASCII decimal.
-}
{-# INLINE intAsciiDec #-}
intAsciiDec :: Int -> Write
intAsciiDec =
  int64AsciiDec . fromIntegral

{-|
Render double interpreting non-real values,
such as @NaN@, @Infinity@, @-Infinity@,
as is.
-}
{-# INLINE doubleAsciiDec #-}
doubleAsciiDec :: Double -> Write
doubleAsciiDec a =
  if a == 0
    then word8 48
    else if isNaN a
      then "NaN"
      else if isInfinite a
        then if a < 0
          then "-Infinity"
          else "Infinity"
        else if a < 0
          then word8 45 <> byteString (ByteString.double (negate a))
          else byteString (ByteString.double a)

{-|
Render double interpreting non real values,
such as @NaN@, @Infinity@, @-Infinity@,
as zero.
-}
{-# INLINE zeroNonRealDoubleAsciiDec #-}
zeroNonRealDoubleAsciiDec :: Double -> Write
zeroNonRealDoubleAsciiDec a =
  if a == 0 || isNaN a || isInfinite a
    then word8 48
    else if a < 0
      then word8 45 <> byteString (ByteString.double (negate a))
      else byteString (ByteString.double a)

{-|
Render Scientific in ASCII decimal.
-}
{-# INLINE scientificAsciiDec #-}
scientificAsciiDec :: Scientific -> Write
scientificAsciiDec =
  byteString . ByteString.scientific

{-|
Efficiently copy the contents of ByteString using @memcpy@.
-}
{-# INLINE byteString #-}
byteString :: ByteString -> Write
byteString a =
  Write (ByteString.length a) (inline Poke.byteString a)

{-|
Render Text in UTF8.

Does pretty much the same as 'Data.Text.Encoding.encodeUtf8',
both implementation and performance-wise,
while allowing you to avoid redundant @memcpy@
compared to @('byteString' . 'Data.Text.Encoding.encodeUtf8')@.

Following are the benchmark results comparing the performance of
@('writeToByteString' . 'textUtf8')@ with
@Data.Text.Encoding.'Data.Text.Encoding.encodeUtf8'@
on inputs in Latin and Greek (requiring different number of surrogate bytes).
The results show that they are quite similar.

=== __Benchmark results__

> textUtf8/ptr-poker/latin/1               mean 57.06 ns  ( +- 3.283 ns  )
> textUtf8/ptr-poker/latin/10              mean 214.1 ns  ( +- 8.601 ns  )
> textUtf8/ptr-poker/latin/100             mean 1.536 μs  ( +- 75.03 ns  )
> textUtf8/ptr-poker/greek/1               mean 85.98 ns  ( +- 5.038 ns  )
> textUtf8/ptr-poker/greek/10              mean 482.1 ns  ( +- 12.38 ns  )
> textUtf8/ptr-poker/greek/100             mean 4.398 μs  ( +- 33.94 ns  )
> textUtf8/text/latin/1                    mean 60.28 ns  ( +- 3.517 ns  )
> textUtf8/text/latin/10                   mean 201.6 ns  ( +- 8.118 ns  )
> textUtf8/text/latin/100                  mean 1.323 μs  ( +- 51.25 ns  )
> textUtf8/text/greek/1                    mean 99.14 ns  ( +- 1.264 ns  )
> textUtf8/text/greek/10                   mean 483.4 ns  ( +- 5.844 ns  )
> textUtf8/text/greek/100                  mean 4.238 μs  ( +- 40.55 ns  )
-}
{-# INLINABLE textUtf8 #-}
textUtf8 :: Text -> Write
textUtf8 =
  byteString . ByteString.textUtf8
