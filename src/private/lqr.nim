import posix, strutils
import nimterop/[build, cimport], glib2

const
  baseDir = getProjectCacheDir("liblqr-nim")
  glibFlags = gorge("pkg-config --cflags glib-2.0")
  glibLibs = gorge("pkg-config --libs glib-2.0")
  flags = "-f:ast2 " & glibFlags

{.passC: glibFlags.}
{.passL: glibLibs.}

static:
    cDebug()
    cSkipSymbol @["G_DATE_DAY",
                  "G_DATE_YEAR",
                  "G_DATE_MONTH",
                  "G_HOOK_FLAG_MASK",
                  "G_CSET_a_2_z"]
    cAddStdDir()
    
cPlugin:
  import
    strutils

  proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
    sym.name = sym.name.strip(chars = {'_'}).replace("__", "_")

# Otherwise glib will complain
cOverride:
  const
    G_LOG_LEVEL_MASK = not 3
  
  type
    GSequenceNode = object
      n_nodes: gint
      parent, left, right: ptr GSequenceNode
      data: gpointer
    
    pthread_mutex_t = Pthread_mutex
    pthread_t = Pthread
    tm = Tm

getHeader(
  "lqr.h",
  giturl = "https://github.com/carlobaldassi/liblqr",
  dlurl = "http://liblqr.wdfiles.com/local--files/en:download-page/liblqr-1-$1.tar.bz2",
  outdir = baseDir,
  conFlags = "--disable-legacy-macros",
  altnames = "liblqr-1"
)

cIncludeDir baseDir

cImport(lqrPath, recurse = true, dynlib = "lqrLPath", flags = flags)
