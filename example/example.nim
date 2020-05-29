import nimBMP
import ../src/lqr

let bmp24 = loadBMP24("image.bmp", seq[uint8])

var buffer = newBuffer(bmp24.width * bmp24.height * 3)
buffer.load(bmp24.data)

let
  carver = newCarver(buffer, bmp24.width, bmp24.height, 3)
  newBMP = carver.resizedLiquid(bmp24.width div 2, bmp24.height div 2)

saveBMP24("image_resized.bmp", newBMP, carver.width, carver.height)
