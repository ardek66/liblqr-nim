import strutils
import nimterop/[build, cimport]

const
  baseDir = getProjectCacheDir("liblqr-nim")
  glibDirs = gorge("pkg-config --cflags glib-2.0").replace("-I", "").split(' ')

static:
    cDebug()
    cAddStdDir()

cPlugin:
  import
    strutils

  proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
    sym.name.removePrefix("gu")
    sym.name.removePrefix("g")
    sym.name = sym.name.strip(chars = {'_'}).replace("__", "_").replace("boolean", "bool")

getHeader(
  "lqr.h",
  giturl = "https://github.com/carlobaldassi/liblqr",
  dlurl = "http://liblqr.wdfiles.com/local--files/en:download-page/liblqr-1-$1.tar.bz2",
  outdir = baseDir,
  conFlags = "--disable-legacy-macros --enable-static",
  altNames = "lqr-1"
)

cIncludeDir baseDir
cIncludeDir(glibDirs, exclude = true)


{.passL: "-lglib-2.0"}

when not defined(lqrStatic):
  cImport(lqrPath, recurse = true, dynLib = "lqrLPath")
else:
  cImport(lqrPath, recurse = true)

