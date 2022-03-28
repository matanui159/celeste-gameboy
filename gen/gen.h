#ifndef GEN_H_
#define GEN_H_
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define GEN_ABS(x) ((x) < 0 ? -(x) : (x))

static uint8_t gen_data[0x8000];

static void gen_load(void) {
    int width, height;
    uint8_t *image = stbi_load("gen/celeste.p8.png", &width, &height, NULL, 4);
    assert(image != NULL);
    for (size_t i = 0; i < sizeof(gen_data); i += 1) {
        uint8_t r = image[i * 4 + 0] & 0x3;
        uint8_t g = image[i * 4 + 1] & 0x3;
        uint8_t b = image[i * 4 + 2] & 0x3;
        uint8_t a = image[i * 4 + 3] & 0x3;
        gen_data[i] = (a << 6) | (r << 4) | (g << 2) | (b << 0);
    }
    stbi_image_free(image);
}

typedef struct gen_palette_t {
    uint8_t index; // the ID of this palette
    uint8_t colors[8]; // The four colors, as PICO-8 colors. Colors 4-7 have the
                       // same index as colors 0-3 and are used for marking
                       // duplicate colors.
} gen_palette_t;

static const gen_palette_t gen_empty_palette = {
    0,
    {0, 0, 0, 0, 0, 0, 0, 0},
};
#define ____ (&gen_empty_palette)

static const gen_palette_t gen_bg_palettes[] = {
    {
        0, // ground & ice
        {0, 5, 12, 7, 0, 5, 12, 7}
    },
    {
        1, // spikes
        {0, 5, 6, 7, 0, 5, 6, 7}
    },
    {
        2, // fall floors
        {0, 1, 4, 9, 0, 1, 4, 9}
    },
    {
        3, // springs
        {0, 5, 4, 9, 0, 5, 4, 9}
    },
    {
        4, // lower tree and grass
        {0, 4, 3, 11, 0, 9, 3, 11}
    },
    {
        5, // upper tree
        {0, 3, 11, 7, 0, 3, 11, 7}
    },
    {
        6, // flower
        {0, 3, 8, 14, 0, 11, 8, 14}
    },
    {
        // TODO: remove this when objects (OAM) are implemented
        7, // player
        {0, 3, 15, 8, 1, 3, 7, 8},
    }
};
#define B(i) (&gen_bg_palettes[i])

static const gen_palette_t gen_obj_palettes[] = {
    {
        0, // player
        {0, 3, 15, 8, 1, 3, 7, 8},
    }
};
#define O(i) (&gen_obj_palettes[i])

static const gen_palette_t *gen_tile_palettes[] = {
B(0),B(7),B(7),B(7),B(7),B(7),B(7),B(7),____,____,____,____,____,____,____,____,
B(0),B(1),B(3),B(3),____,____,____,B(2),B(2),B(2),____,B(1),____,____,____,____,
B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(1),B(5),____,____,____,
B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(0),B(1),B(4),B(4),B(6),B(4),
B(0),B(0),B(0),B(0),B(0),B(0),____,____,B(0),____,____,____,____,____,____,____,
B(0),B(0),B(0),B(0),B(0),B(0),____,____,B(0),____,____,____,____,____,____,____,
____,____,B(0),B(0),B(0),B(0),____,B(0),B(0),____,____,____,____,____,____,____,
____,____,B(0),B(0),B(0),____,____,____,____,____,____,____,____,____,____,____
};

#endif
