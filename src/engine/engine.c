#include "engine.h"

void engine_init(void) {
    video_init();
    gb_ie = GB_INT_VBLANK;
    gb_if = 0x00;
    gb_int(1);
}
