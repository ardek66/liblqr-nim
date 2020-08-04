import sequtils
import imageman
import private/lqr

type
  Carver* = object
    impl: ptr LqrCarver

  Buffer* = object
    impl: ptr UncheckedArray[uint8]
    size: uint
    freed: bool
    
template `->`(a: typed, T: typedesc): ptr T =
  cast[ptr T](a.addr)

template `[]`*(buffer: Buffer, i: int): uint8 =
  buffer.impl[i].uint8

template `[]=`*(buffer: Buffer, i: int, data: uint8) =
  buffer.impl[i] = data

proc newBuffer*(size: int): Buffer =
  result.impl = cast[ptr UncheckedArray[uint8]](alloc0(size))
  result.size = size.uint

proc newCarver*(buffer: var Buffer, width, height, channels: int, col_depth: LqrColDepth): Carver =
  result.impl = lqr_carver_new_ext(buffer.impl, width.cint, height.cint, channels.cint, col_depth)
  
proc `=destroy`*(carver: var Carver) =
  lqr_carver_destroy(carver.impl)
  carver.impl = nil

#proc `=destroy`*(buffer: var Buffer) =
#  if not buffer.freed:
#    dealloc(buffer.impl)
#    buffer.freed = true
#    buffer.impl = nil

proc load*(buffer: var Buffer, src: openArray[ColorRGBU]) =
  moveMem(buffer.impl, unsafeAddr src, buffer.size)

proc init*(carver: Carver, deltaX: int = 1, rigidity: float = 0) =
  discard lqr_carver_init(carver.impl, deltaX.cint, rigidity.cfloat)
  lqr_carver_set_preserve_input_image(carver.impl)

proc resize*(carver: Carver, w1, h1: int) =
  discard lqr_carver_resize(carver.impl, w1.cint, h1.cint)

proc width*(carver: Carver): int =
  lqr_carver_get_width(carver.impl)

proc height*(carver: Carver): int =
  lqr_carver_get_height(carver.impl)

proc resetScan*(carver: Carver) =
  lqr_carver_scan_reset(carver.impl)

proc scan*(carver: Carver, x, y: var int, rgb: var openArray[uint8]): bool =
  result = (lqr_carver_scan_ext(carver.impl, x, y, rgb)).bool

proc resizedLiquid*(carver: Carver, w, h: int): seq[uint8] =
  carver.init
  carver.resize(w, h)

  result = newSeq[uint8](w * h * 3)
  var
    x, y: int
    rgb: Buffer
  while(carver.scan(x, y, rgb)):
    if x > w or y > h: break
    for k in 0..2:
      result[(y * w + x) * 3 + k] = rgb[k]

proc resizedLiquid*(img: var Image[ColorRGBU], w, h: int) =
  var buffer = newBuffer(img.data.len * 3)
  buffer.load(img.data)
  var carver = newCarver(buffer, img.width, img.height, 3, LQR_COLDEPTH_8I)
  img = initImage[ColorRGBU](w, h)
  img.data = cast[seq[ColorRGBU]](carver.resizedLiquid(w, h))
