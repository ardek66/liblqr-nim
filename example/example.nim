import nimPNG
import ../src/lqr

var pix: PNGResult[seq[uint8]]

let res = loadPNG24(seq[uint8], "image.png")
if res.isOk(): pix = res.get()

let
  newWidth = pix.width div 2
  newHeight = pix.height div 2

var carver = newCarver(pix.data, pix.width, pix.height, 3)
let newPNG = carver.resizedLiquid(newWidth, newHeight)

discard savePNG24("image_resized.png", newPNG, newWidth, newHeight)
