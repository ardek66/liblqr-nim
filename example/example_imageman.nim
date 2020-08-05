import imageman
import ../src/lqr
var img = loadImage[ColorRGBU]("image.png")
img = img.resizedLiquid(img.width, img.height)
img.savePNG("image_resized.png")
