import imageman
import ../src/lqr

var img = loadImage[ColorRGBU]("image.png")
img.resizedLiquid(img.width div 2, img.height div 2)
img.savePNG("image_resized.png")
