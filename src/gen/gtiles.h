#ifndef GEN_TILES_H_
#define GEN_TILES_H_
#include "../engine/gameboy.h"

#define GAME_TILES 128

extern const unsigned short game_dmg_tiles[GAME_TILES * GB_TILE_ROWS];
extern const unsigned short game_cgb_tiles[GAME_TILES * GB_TILE_ROWS];

#endif
