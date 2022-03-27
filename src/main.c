#include "engine/engine.h"

void main(void) {
    engine_init();
    gb_lcdc |= GB_LCDC_ENABLE;
    video_wait();
    video_wait();
    map_load(0x00);
}
