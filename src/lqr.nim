import sequtils
import imageman
import private/lqr

type
  Buffer* = object
    impl: ptr UncheckedArray[guchar]
    size: int
    freed: bool

  Carver* = object
    impl: ptr LqrCarver

template `->`(a: typed, T: typedesc): ptr T =
  cast[ptr T](a.addr)

template `[]`*(buffer: Buffer, i: int): uint8 =
  buffer.impl[i].uint8

template `[]=`*(buffer: Buffer, i: int, data: uint8) =
  buffer.impl[i] = data.guchar

proc newBuffer*(size: int): Buffer =
  var mem = g_try_malloc(size.gsize)
  result.impl = cast[Buffer.impl](mem)
  result.size = size

proc newCarver*(buffer: var Buffer, width, height, channels: int): Carver =
  result.impl = lqr_carver_new(cast[ptr guchar](buffer.impl), width.gint, height.gint, channels.gint)
  buffer.freed = true

proc `=destroy`*(carver: var Carver) =
  lqr_carver_destroy(carver.impl)
  carver.impl = nil

proc `=destroy`*(buffer: var Buffer) =
  if not buffer.freed:
    g_free(buffer.impl)
    buffer.impl = nil
    buffer.freed = true

proc load*(buffer: var Buffer, src: openArray[uint8]) =
  moveMem(buffer.impl, unsafeAddr src, buffer.size)

proc init*(carver: Carver, deltaX: int = 1, rigidity: float = 0) =
  discard lqr_carver_init(carver.impl, deltaX.gint, rigidity.gfloat)

proc resize*(carver: Carver, w1, h1: int) =
  discard lqr_carver_resize(carver.impl, w1.gint, h1.gint)

proc width*(carver: Carver): int =
  lqr_carver_get_width(carver.impl)

proc height*(carver: Carver): int =
  lqr_carver_get_height(carver.impl)

proc resetScan*(carver: Carver) =
  lqr_carver_scan_reset(carver.impl)

proc scan*(carver: Carver, x, y: var int, rgb: var Buffer): bool =
  result = (lqr_carver_scan(carver.impl, x->gint, y->gint, rgb->(ptr guchar))).bool
  rgb.freed = true

proc resizedLiquid*(carver: Carver, w, h: int): seq[uint8] =
  carver.init
  carver.resize(w, h)

  result = newSeq[uint8](w * h * 3)
  var
    x, y: int
    rgb: Buffer
  while(carver.scan(x, y, rgb)):
    for k in 0..2:
      result[(y * w + x) * 3 + k] = rgb[k]

proc resizedLiquid*(img: var Image[ColorRGBU], w, h: int) =
  var buffer = newBuffer(img.width * img.height * 3)
  buffer.load(cast[seq[uint8]](img.data))
  
  var carver = newCarver(buffer, img.width, img.height, 3)
  
  img = initImage[ColorRGBU](w, h)
  img.data = cast[seq[ColorRGBU]](carver.resizedLiquid(w, h))
  
