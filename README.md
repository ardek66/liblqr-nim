# liblqr-nim #
Liblqr-nim is a Nim wrapper for the [liblqr](https://github.com/carlobaldassi/liblqr) C/C++ library. It's aim is to be easy to use and compatible with most Nim image libraries.

## Compatibility ##

liblqr-nim can use [imageman](https://github.com/SolitudeSF/imageman) images which should be enough in most cases. This is straightforward and does not require any function call other than `resizedLiquid`.

Otherwise, liblqr-nim provides the `Carver` type for defining an image to be resized, provided with the image data as a sequence or array, width, height and number of channels.

The following data types are available for image data sequences:

+ `uint8`
+ `uint16`
+ `float32`
+ `float64`


## Ease of use ##

This wrapper aims to be easy to use in Nim, albeit at the cost of flexibility provided by the library(but in 99% of the cases it should be enough).

All the complicated C-ish parts are wrapped internally and only 1-2 functions are required for rescaling.
