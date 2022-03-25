#ifndef ENGINE_VIDEO_H_
#define ENGINE_VIDEO_H_
#include "compat.h"

void palcpy(ubyte reg, ubyte dst, const uint *src, ubyte size);
void video_init(void);

#endif
