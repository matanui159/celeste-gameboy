#ifndef GEN_TILES_H_
#define GEN_TILES_H_
#include "../engine/gameboy.h"

#define GAME_TILE_COUNT 128

extern const unsigned char game_dmg_tiles[GAME_TILE_COUNT * GB_TILE_SIZE];
extern const unsigned char game_cgb_tiles[GAME_TILE_COUNT * GB_TILE_SIZE];

#endif
