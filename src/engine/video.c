#include "video.h"
#include "../gen/gtiles.h"
#include "../gen/gpalettes.h"
#include <string.h>

void video_init(void) {
    if (gb_lcdc & GB_LCDC_ENABLE) {
        gb_ie = GB_INT_VBLANK;
        gb_if = 0x00;
        gb_halt();
        gb_lcdc = 0x00;
    }

    if (crt_boot == CRT_BOOT_CGB) {
        memcpy(gb_tile_data0, game_cgb_tiles, sizeof(game_cgb_tiles));
        palcpy((ubyte)&cgb_bgpi, 0x00, game_bg_palettes, sizeof(game_bg_palettes) / 2);
        palcpy((ubyte)&cgb_obpi, 0x00, game_obj_palettes, sizeof(game_obj_palettes) / 2);
    } else {
        memcpy(gb_tile_data0, game_dmg_tiles, sizeof(game_dmg_tiles));
        ubyte pal = GB_PALETTE(3, 2, 1, 0);
        gb_bgp = pal;
        gb_obp0 = pal;
        gb_obp1 = pal;
    }
}
