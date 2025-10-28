/* hal/win_compat.h */
#pragma once

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

/* MSVC / Windows headers */
#include <windows.h>
#include <io.h>         /* _access, _close, _dup, _dup2, _isatty, _open, _read, _write, _unlink */
#include <process.h>    /* _getpid */
#include <direct.h>     /* _mkdir */
#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>

/* Map common POSIX APIs/macros used in hal/library.c to Win32 equivalents */
#define access      _access
#define unlink      _unlink
#define getpid      _getpid
#define mkdir(p, m) _mkdir(p)      /* ignore mode on Windows */

/* sleep/usleep */
#define sleep(sec)  (Sleep((DWORD)((sec) * 1000)), 0)
static __inline int usleep(unsigned int usec) {
    /* Sleep takes milliseconds; round up so 1..999us -> 1ms */
    DWORD ms = (usec + 999U) / 1000U;
    Sleep(ms);
    return 0;
}

/* If code includes <unistd.h>, include this file instead without editing sources.
   You can also create hal/unistd.h as a one-liner: #include "win_compat.h" */

#endif /* _WIN32 */
