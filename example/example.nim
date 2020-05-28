import nimBMP
import ../src/lqr

let bmp24 = loadBMP24("image.bmp", seq[uint8])

# Create a buffer and load the image data in it
var buffer = newBuffer(bmp24.width * bmp24.height * 3)

for i, c in bmp24.data:
  buffer[i] = c

# Initialise the carver
let carver = newCarver(buffer, bmp24.width, bmp24.height, 3)
carver.init

# The actual rescaling
let
  new_width = bmp24.width div 2
  new_height = bmp24.height div 2

carver.resize(new_width, new_height)

# Scan and save the rescaled image
var
  x, y: int
  rgb: Buffer
  pixels = newSeq[uint8](new_width * new_height * 3)

carver.resetScan

while(carver.scan(x, y, rgb)):
  for k in 0..2:
    pixels[(y * new_width + x) * 3 + k] = rgb[k]

saveBMP24("image_resized.bmp", pixels, carver.width, carver.height)
