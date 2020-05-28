import private/lqr

type
  Buffer* = object
    impl: ptr UncheckedArray[char]
    freed: bool
  
  Carver* = object
    impl: ptr LqrCarver

template `->`(a: typed, T: typedesc): ptr T =
  cast[ptr T](a.addr)

proc `[]`*(buffer: Buffer, i: int): uint8 =
  buffer.impl[i].uint8

proc `[]=`*(buffer: Buffer, i: int, data: uint8) =
  buffer.impl[i] = data.guchar

proc newBuffer*(size: int): Buffer =
  var mem = g_try_malloc(size.gsize)
  result.impl = cast[Buffer.impl](mem)

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
