#ifndef ENGINE_GAMEBOY_H_
#define ENGINE_GAMEBOY_H_
#include "compat.h"

#define GB_TILE_ROWS 8
#define GB_BLOCK_TILES 128

ADDR(0x8000) uint gb_tile_data0[GB_BLOCK_TILES * GB_TILE_ROWS];
ADDR(0x8800) uint gb_tile_data1[GB_BLOCK_TILES * GB_TILE_ROWS];
ADDR(0x9000) uint gb_tile_data2[GB_BLOCK_TILES * GB_TILE_ROWS];

#define GB_MAP_SIZE 32
#define GB_MAP_TILES (GB_MAP_SIZE * GB_MAP_SIZE)

ADDR(0x9800) ubyte gb_tile_map0[GB_MAP_TILES];
ADDR(0x9c00) ubyte gb_tile_map1[GB_MAP_TILES];

typedef enum cgb_map_flags_t {
    CGB_MAP_PALETTE_MASK = 0x07,
    CGB_MAP_BANK1 = 0x08,
    CGB_MAP_FLIP_X = 0x20,
    CGB_MAP_FLIP_Y = 0x40,
    CGB_MAP_PRIORITY = 0x80
} cgb_map_flags_t;

ADDR(0x9800) ubyte cgb_tile_attr0[GB_MAP_TILES];
ADDR(0x9c00) ubyte cgb_tile_attr1[GB_MAP_TILES];

#define GB_OBJECT_COUNT 40

typedef enum gb_object_flags_t {
    CGB_OBJECT_PALETTE_MASK = 0x07,
    CGB_OBJECT_BANK1 = 0x08,
    GB_OBJECT_PALETTE = 0x10,
    GB_OBJECT_FLIP_X = 0x20,
    GB_OBJECT_FLIP_Y = 0x40,
    GB_OBJECT_NO_PRIORITY = 0x80
} gb_object_flags_t;

typedef struct gb_object_t {
    ubyte y;
    ubyte x;
    ubyte tile;
    ubyte attr;
} gb_object_t;

ADDR(0xfe00) gb_object_t gb_oam[GB_OBJECT_COUNT];

typedef enum gb_int_flags_t {
    GB_INT_VBLANK = 0x01,
    GB_INT_STAT = 0x02,
    GB_INT_TIMA = 0x04,
    GB_INT_JOYP = 0x10
} gb_int_flags_t;

ADDR(0x0f) hbyte gb_if;
ADDR(0xff) hbyte gb_ie;

typedef enum gb_lcdc_flags_t {
    GB_LCDC_BG_ENABLE = 0x01,
    CGB_LCDC_BG_PRIORITY = 0x01,
    GB_LCDC_OBJ_ENABLE = 0x02,
    GB_LCDC_OBJECT16 = 0x04,
    GB_LCDC_BG_MAP1 = 0x08,
    GB_LCDC_BG_DATA0 = 0x10,
    GB_LCDC_WINDOW_ENABLE = 0x20,
    GB_LCDC_WINDOW_MAP1 = 0x40,
    GB_LCDC_ENABLE = 0x80
} gb_lcdc_flags_t;

ADDR(0x40) hbyte gb_lcdc;

typedef enum gb_stat_type_t {
    GB_STAT_HBLANK,
    GB_STAT_VBLANK,
    GB_STAT_OAM,
    GB_STAT_DRAW
} gb_stat_type_t;

typedef enum gb_stat_flags_t {
    GB_STAT_TYPE_MASK = 0x03,
    GB_STAT_LYC = 0x04,
    GB_STAT_INT_HBLANK = 0x08,
    GB_STAT_INT_VBLANK = 0x10,
    GB_STAT_INT_OAM = 0x20,
    GB_STAT_INT_LYC = 0x40
} gb_stat_flags_t;

ADDR(0x41) hbyte gb_stat;

#define GB_PALETTE(a, b, c, d) (((a) << 0) | ((b) << 2) | ((c) << 4) | ((d) << 6))

ADDR(0x47) hbyte gb_bgp;
ADDR(0x48) hbyte gb_obp0;
ADDR(0x49) hbyte gb_obp1;

ADDR(0x4f) hbyte cgb_vbank;

#define CGB_PALETTE_COLORS 4

typedef enum cgb_palette_flags_t {
    CGB_PALETTE_INC = 0x80
} cgb_palette_flags_t;

ADDR(0x68) hbyte cgb_bgpi;
ADDR(0x69) hbyte cgb_bgpd;
ADDR(0x6a) hbyte cgb_obpi;
ADDR(0x6b) hbyte cgb_obpd;

typedef enum crt_boot_type_t {
    CRT_BOOT_CGB = 0x11
} crt_boot_t;

ADDR(0x80) hbyte crt_boot;

inline void gb_halt(void) {
#ifdef __SDCC_sm83
    __asm
        halt
        nop
    __endasm;
#endif
}

inline void gb_int(ubyte enable) {
#ifdef __SDCC_sm83
    if (enable) {
        __asm
            ei
        __endasm;
    } else {
        __asm
            di
        __endasm;
    }
#endif
}

#endif
