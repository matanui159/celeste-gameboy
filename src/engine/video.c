#include "video.h"
#include "gameboy.h"
#include "../gen/gtiles.h"
#include "../gen/gpalettes.h"
#include <string.h>

void _int_vblank(void) INTERRUPT {
}

void video_wait(void) {
    if (gb_lcdc & GB_LCDC_ENABLE) {
        ubyte ie = gb_ie;
        gb_ie = GB_INT_VBLANK;
        gb_if &= ~GB_INT_VBLANK;
        gb_halt();
        gb_ie = ie;
    }
}

void video_init(void) {
    video_wait();
    // The first call to `map_load` will enable the LCDC
    gb_lcdc = GB_LCDC_BG_ENABLE | CGB_LCDC_BG_PRIORITY | GB_LCDC_BG_DATA0;
    if (crt_boot == CRT_BOOT_CGB) {
        memcpy(gb_tile_data0, game_cgb_tiles, sizeof(game_cgb_tiles));
        palcpy((ubyte)&cgb_bgpi, 0x00, game_bg_palettes, sizeof(game_bg_palettes));
        palcpy((ubyte)&cgb_obpi, 0x00, game_obj_palettes, sizeof(game_obj_palettes));
    } else {
        memcpy(gb_tile_data0, game_dmg_tiles, sizeof(game_dmg_tiles));
        ubyte pal = GB_PALETTE(3, 2, 1, 0);
        gb_bgp = pal;
        gb_obp0 = pal;
        gb_obp1 = pal;
    }
}
