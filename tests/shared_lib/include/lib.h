#ifndef LIB_H
#define LIB_H

#if defined(_WIN32)
#if defined(mylib_EXPORTS)
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __declspec(dllimport)
#endif
#else
#define EXPORT
#endif

EXPORT int mul(int a, int b);

#endif
