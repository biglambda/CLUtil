-- Port of the quasicrystal animation code at:
-- http://mainisusuallyafunction.blogspot.com/2011/10/quasicrystals-as-sums-of-waves-in-plane.html
-- This is a more thoughtfully optimized version of
-- QuasiCrystalDisplay.hs. The optimization strategies are to precompute
-- sines and cosines of the chosen angles, then assume that we are
-- working with exactly 7 angles in the kernel code which then
-- performs vectorized calculations.
import CLUtil
import qualified Data.Vector.Storable as V
import Data.Word (Word8)
import Graphics.Gloss hiding (Vector, scale)
import Graphics.Gloss.Interface.IO.Animate hiding (Vector, scale)

pixels :: Int
pixels = 800

scale :: Float
scale = 128

angles :: Int -> Vector Float
angles n = V.map (* (pi / fromIntegral n)) $ V.enumFromN 0 n

mkPicture :: Vector Word8 -> Picture
mkPicture v = bitmapOfForeignPtr pixels
                                 pixels
                                 (BitmapFormat BottomToTop PxABGR)
                                 (fst (V.unsafeToForeignPtr0 v))
                                 False

main :: IO ()
main = do s <- ezInit CL_DEVICE_TYPE_ALL
          k <- kernelFromFile s "examples/QuasiCrystalRGBAFast.cl"
                                "quasiCrystal"
          let numPix = pixels * pixels
              pixels' = fromIntegral pixels :: Int32
              numAngles = 7
              allAngles = angles numAngles
              sines = V.snoc (V.map sin allAngles) 0
              cosines = V.snoc (V.map cos allAngles) 0
              frame :: Float -> CL Picture
              frame phase = mkPicture `fmap`
                            runKernel k pixels' scale phase
                                      sines cosines
                                      (Out (numPix*4))
                                      (Work2D pixels pixels)
          animateIO (InWindow "Quasicrystal" (pixels,pixels) (0,0))
                    black
                    (runCL s . frame)
                    (const (return ()))
