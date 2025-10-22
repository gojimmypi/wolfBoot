#ifndef _WIN32
#  error "This shim is for Windows/MSVC only"
#endif
#include <io.h>
#include <process.h>
#include <direct.h>
#include <stdlib.h>

#ifndef ssize_t
#  ifdef _WIN64
     typedef long long ssize_t;
#  else
     typedef int ssize_t;
#  endif
#endif

#ifndef unlink
#  define unlink _unlink
#endif
#ifndef close
#  define close _close
#endif
#ifndef read
#  define read _read
#endif
#ifndef write
#  define write _write
#endif
#ifndef access
#  define access _access
#endif
