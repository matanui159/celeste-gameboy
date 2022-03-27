#include "map.h"
#include "gameboy.h"
#include "video.h"
#include "../gen/gmaps.h"
#include "../gen/gattrs.h"
#include <string.h>

static ubyte map_tiles[GAME_MAP_TILES];

void map_load(ubyte id) CRITICAL {
    ubyte *map = map_tiles;
    memcpy(map, &game_maps[id * GAME_MAP_TILES], sizeof(map_tiles));
    video_wait();

    // Copy first row now during V-blank
    ubyte *gb = gb_tile_map0;
    for (ubyte x = 0; x < GAME_MAP_SIZE; x += 1) {
        ubyte tile = *(map++);
        *gb = tile;
        // Copy attributes if CGB
        if (crt_boot == CRT_BOOT_CGB) {
            ubyte attr = game_attrs[tile] & GAME_TILE_PALETTE_MASK;
            cgb_vbank = 1;
            *gb = attr;
            cgb_vbank = 0;
        }
        gb += 1;
    }
    gb += GB_MAP_SIZE - GAME_MAP_SIZE;

    // Setup registers for H-blank interrupts
    ubyte stat = gb_stat;
    ubyte ie = gb_ie;
    gb_lcdc |= GB_LCDC_ENABLE;
    gb_stat = GB_STAT_INT_HBLANK;
    gb_ie = GB_INT_STAT;

    // Copy one tile per H-blank
    for (ubyte y = 1; y < GAME_MAP_SIZE; y += 1) {
        for (ubyte x = 0; x < GAME_MAP_SIZE; x += 1) {
            ubyte tile = *(map++);
            ubyte attr = game_attrs[tile] & GAME_TILE_PALETTE_MASK;
            map_hblank(gb++, tile, attr);
        }
        gb += GB_MAP_SIZE - GAME_MAP_SIZE;
    }

    gb_stat = stat;
    gb_ie = ie;
}
