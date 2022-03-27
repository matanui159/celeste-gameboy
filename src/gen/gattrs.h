#ifndef GEN_ATTRS_H_
#define GEN_ATTRS_H_
#include "gtiles.h"
#include "../engine/gameboy.h"

typedef enum game_tile_flags_t {
    GAME_TILE_PALETTE_MASK = CGB_MAP_PALETTE_MASK,
    GAME_TILE_SOLID = 0x08,
    GAME_TILE_ICE = 0x10
} game_tile_flags_t;

extern const unsigned char game_attrs[GAME_TILES];

#endif
