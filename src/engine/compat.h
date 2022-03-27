#ifndef ENGINE_COMPAT_H_
#define ENGINE_COMPAT_H_
#include <stddef.h>

typedef signed char sbyte;
typedef unsigned char ubyte;
typedef signed short sint;
typedef unsigned short uint;

#ifdef __SDCC
typedef __sfr hbyte;
#define ADDR(addr) __at(addr)
#define CRITICAL __critical
#define INTERRUPT CRITICAL __interrupt
#else
typedef ubyte hbyte;
#define ADDR(addr)
#define CRITICAL
#define INTERRUPT CRITICAL
#endif

#endif
