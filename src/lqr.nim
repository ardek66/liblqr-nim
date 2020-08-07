import sequtils
import imageman
import private/lqr

type
  ColorTypes = ColorComponent | uint16
  
  Carver*[T: ColorTypes] = object
    impl: ptr LqrCarver
    
template `->`(a: typed, T: typedesc): ptr T =
  cast[ptr T](a.addr)

template colDepthType(T: typedesc[ColorTypes]): LqrColDepth =
  when T is uint16: LQR_COLDEPTH_16I
  elif T is float32: LQR_COLDEPTH_32F
  elif T is float64: LQR_COLDEPTH_64F
  else: LQR_COLDEPTH_8I

template colBufType(T: typedesc[ColorTypes]): typedesc[ColorRGBAny] =
  when T is float32: ColorRGBAF
  elif T is float64: ColorRGBAF64
  else: ColorRGBAU

proc resize(carver: Carver, w, h: int) =
  discard lqr_carver_resize(carver.impl, w.cint, h.cint)

proc newCarver*[T: ColorTypes](data: openArray[T], w, h, channels: int): Carver[T] =
  result.impl = lqr_carver_new_ext(cast[ptr UncheckedArray[T]](data),
                                   w.cint, h.cint, channels.cint,
                                   colDepthType(T))
  
  discard lqr_carver_init(result.impl, 1, 0)
  lqr_carver_set_use_cache(result.impl, false)
  lqr_carver_set_preserve_input_image(result.impl)

proc `=destroy`*[T: ColorTypes](carver: var Carver[T]) =
  if carver.impl != nil:
    lqr_carver_destroy(carver.impl)
    carver.impl = nil

proc width*(carver: Carver): int =
  lqr_carver_get_width(carver.impl)

proc height*(carver: Carver): int =
  lqr_carver_get_height(carver.impl)

proc channels*(carver: Carver): int =
  lqr_carver_get_channels(carver.impl)

iterator scan[T: ColorTypes](carver: Carver[T]): tuple[x, y: int, rgb: ColorRGBAny] =
  var
    rgb: ptr UncheckedArray[T]
    x, y: int
  
  lqr_carver_scan_reset(carver.impl)
  while lqr_carver_scan_ext(carver.impl, x->cint, y->cint, rgb->pointer).bool:
    var color: colBufType(T)
    copyMem addr color, rgb, sizeof color
    yield (x, y, color)

proc resizedLiquid*[T: ColorTypes](carver: Carver[T], w, h: int): seq[T] =
  result = newSeq[T](w * h * carver.channels)
  carver.resize w, h
  
  for x, y, rgb in carver.scan:
    for i in 0..<carver.channels:
      result[(y * w + x) * carver.channels + i] = rgb[i]

proc resizedLiquid*[T: ColorRGBAny](img: var Image[T], w, h: int) =
  let carver = newCarver(cast[seq[componentType(T)]](img.data), img.width, img.height, T.len)
  carver.resize w, h
  
  img = initImage[T](w, h)
  for x, y, rgb in carver.scan:
    img[x, y] = rgb.to T
