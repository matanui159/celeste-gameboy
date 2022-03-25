#ifndef GEN_PALETTES_H_
#define GEN_PALETTES_H_
#include "../engine/gameboy.h"

#define GAME_BG_PALETTE_COUNT 8
#define GAME_OBJ_PALETTE_COUNT 1

extern const unsigned short game_bg_palettes[GAME_BG_PALETTE_COUNT * CGB_PALETTE_SIZE];
extern const unsigned short game_obj_palettes[GAME_OBJ_PALETTE_COUNT * CGB_PALETTE_SIZE];

#endif
