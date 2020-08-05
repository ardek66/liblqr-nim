import sequtils
import imageman
import private/lqr

type
  ColorTypes = uint8 | uint16 | float32 | float64
  
  Carver*[T: ColorTypes] = object
    impl: ptr LqrCarver
    buffer: Buffer[T]

  Buffer[T: ColorTypes] = object
    impl: ptr UncheckedArray[T]
    size: uint
    
template `->`(a: typed, T: typedesc): ptr T =
  cast[ptr T](a.addr)

template colDepthType(t: typedesc[ColorTypes]): LqrColDepth =
  when t is uint16: LQR_COLDEPTH_16I
  elif t is float32: LQR_COLDEPTH_32F
  elif t is float64: LQR_COLDEPTH_64F
  else: LQR_COLDEPTH_8I

proc init(carver: Carver, deltaX: int = 1, rigidity: float = 0) =
  discard lqr_carver_init(carver.impl, deltaX.cint, rigidity.cfloat)
  lqr_carver_set_preserve_input_image(carver.impl)

proc resize(carver: Carver, w1, h1: int) =
  discard lqr_carver_resize(carver.impl, w1.cint, h1.cint)

proc resetScan(carver: Carver) =
  lqr_carver_scan_reset(carver.impl)

proc scan[T: ColorTypes](carver: Carver[T], x, y: var int, rgb: var Buffer[T]): bool =
  result = (lqr_carver_scan_ext(carver.impl, x->cint, y->cint, rgb.impl->pointer)).bool

proc newBuffer[T: ColorTypes](size: int): Buffer[T] =
  result.impl = cast[ptr UncheckedArray[T]](alloc0(size))
  result.size = size.uint

proc newCarver*[T: ColorTypes](data: openArray[T], width, height, channels: int): Carver[T] =
  result.buffer = newBuffer[T](width * height * channels)
  moveMem(result.buffer.impl, unsafeAddr data, result.buffer.size)
  result.impl = lqr_carver_new_ext(result.buffer.impl, width.cint, height.cint, channels.cint, colDepthType(T))
  result.init

proc `=destroy`*[T: ColorTypes](carver: var Carver[T]) =
  if carver.impl != nil:
    lqr_carver_destroy(carver.impl)
    carver.impl = nil
    if carver.buffer.impl != nil:
      dealloc(carver.buffer.impl)
      carver.buffer.impl = nil

proc width*(carver: Carver): int =
  lqr_carver_get_width(carver.impl)

proc height*(carver: Carver): int =
  lqr_carver_get_height(carver.impl)

proc channels*(carver: Carver): int =
  lqr_carver_get_channels(carver.impl)

proc resizedLiquid*[T: ColorTypes](carver: Carver[T], w, h: int): seq[T] =
  let channels = carver.channels
  
  carver.resize(w, h)

  result = newSeq[T](w * h * channels)
  var
    x, y: int
    rgb: Buffer[T]
  carver.resetScan()
  while(carver.scan(x, y, rgb)):
    if x > w or y > h: break
    for k in 0..<channels:
      result[(y * w + x) * channels + k] = rgb.impl[k]

proc resizedLiquid*[T: ColorRGBUAny](img: Image[T], w, h: int): Image[T] =
  var data: seq[componentType(T)]
  copyMem addr data, unsafeAddr img.data, sizeof img.data
  
  var carver = newCarver(data, img.width, img.height, T.len)
  result = initImage[T](w, h)
  data = carver.resizedLiquid(w, h)
  for i in 0..result.data.high:
    for j in 0..T.high:
      result.data[i][j] = data[i * T.len + j]
