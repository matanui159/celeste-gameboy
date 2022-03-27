#ifndef GEN_PALETTES_H_
#define GEN_PALETTES_H_
#include "../engine/gameboy.h"

#define GAME_BG_PALETTES 8
#define GAME_OBJ_PALETTES 1

extern const unsigned short game_bg_palettes[GAME_BG_PALETTES * CGB_PALETTE_COLORS];
extern const unsigned short game_obj_palettes[GAME_OBJ_PALETTES * CGB_PALETTE_COLORS];

#endif
