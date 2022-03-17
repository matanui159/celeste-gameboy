#ifndef GEN_H_
#define GEN_H_
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

static uint8_t pico8_data[0x8000];

static void load_pico8(void) {
    int width, height;
    uint8_t *image = stbi_load("gen/celeste.p8.png", &width, &height, NULL, 4);
    assert(image != NULL);
    for (size_t i = 0; i < sizeof(pico8_data); i += 1) {
        uint8_t r = image[i * 4 + 0] & 0x3;
        uint8_t g = image[i * 4 + 1] & 0x3;
        uint8_t b = image[i * 4 + 2] & 0x3;
        uint8_t a = image[i * 4 + 3] & 0x3;
        pico8_data[i] = (a << 6) | (r << 4) | (g << 2) | (b << 0);
    }
    stbi_image_free(image);
}

typedef struct gen_palette_t {
    uint8_t indices[16]; // maps pico8 colors to gameboy palette indices
    uint8_t dmg_colors[4]; // the four gameboy shades, used to generate dmg tiles
    uint8_t cgb_colors[4]; // the four CGB shades, as pico8 colors
} gen_palette_t;

static const gen_palette_t game_palettes[] = {
    {
        // ground & ice
        {0,0,0,0,0,1,0,3,0,0,0,0,2,0,0,0},
        {0, 0, 2, 3},
        {0, 5, 12, 7}
    },
    {
        // spikes
        {0,0,0,0,0,1,2,3,0,0,0,0,0,0,0,0},
        {0, 0, 2, 3},
        {0, 5, 6, 7}
    },
    {
        // fall floors
        {0,1,0,0,2,0,0,0,0,3,0,0,0,0,0,0},
        {0, 1, 2, 2},
        {0, 1, 4, 9}
    },
    {
        // springs
        {0,0,0,0,2,1,0,0,0,3,0,0,0,0,0,0},
        {0, 1, 2, 2},
        {0, 5, 4, 9}
    },
    {
        // upper tree and grass
        {0,0,0,1,0,0,0,3,0,0,0,2,0,0,0,0},
        {0, 2, 2, 3},
        {0, 3, 11, 7}
    },
    {
        // lower tree
        {0,0,0,2,1,0,0,0,0,1,0,3,0,0,0,0},
        {0, 1, 2, 2},
        {0, 4, 3, 11}
    },
    {
        // flower
        {0,0,0,1,0,0,0,0,2,0,0,1,0,0,3,0},
        {0, 1, 1, 2},
        {0, 3, 8, 14}
    },
    {
        // player
        // TODO: move this to object palettes when objects (OAM) are implemented
        {0,0,0,1,0,0,0,2,3,0,0,0,0,0,0,2},
        {0, 1, 2, 3},
        {0, 3, 15, 8},
    }
};

static const int tile_palettes[] = {
     0, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 3, 3, 0, 0, 0, 2, 2, 2, 0, 1, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 4, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5, 4, 6, 4,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

#endif
