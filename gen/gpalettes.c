#include "gen.h"

static const uint32_t pico8_colors[] = {
    0x000000,
    0x1d2b53,
    0x7e2553,
    0x008751,
    0xab5236,
    0x5f574f,
    0xc2c3c7,
    0xfff1e8,
    0xff004d,
    0xffa300,
    0xffec27,
    0x00e436,
    0x29adff, 
    0x83769c,
    0xff77a8, 
    0xffccaa
};

// Copied from Sameboy
static const uint8_t cgb_shades[] = {
      0,   6,  12,  20,  28,  36,  45,  56,
     66,  76,  88, 100, 113, 125, 137, 149,
    161, 172, 182, 192, 202, 210, 218, 225,
    232, 238, 243, 247, 250, 252, 254, 255
};

static uint8_t get_cgb_index(uint8_t shade) {
    uint8_t index;
    int dist = -1;
    for (size_t i = 0; i < sizeof(cgb_shades); i += 1) {
        uint8_t new_dist = MATH_ABS(cgb_shades[i] - shade);
        if (dist < 0 || new_dist < dist) {
            index = i;
            dist = new_dist;
        }
    }
    return index;
}

static void print_palettes(
    const char *name,
    size_t pal_size,
    const gen_palette_t *palettes
) {
    printf("const unsigned short %s[] = {\n", name);
    size_t pal_count = pal_size / sizeof(gen_palette_t);
    for (size_t p = 0; p < pal_count; p += 1) {
        const gen_palette_t *pal = &palettes[p];
        printf("   ");
        for (size_t c = 0; c < 4; c += 1) {
            uint32_t color = pico8_colors[pal->cgb_colors[c]];
            uint8_t r = get_cgb_index((color >> 16) & 0xff);
            uint8_t g = get_cgb_index((color >>  8) & 0xff);
            uint8_t b = get_cgb_index((color >>  0) & 0xff);
            uint16_t cgb = (r << 0) | (g << 5) | (b << 10);
            printf(" 0x%04x,", cgb);
        }
        printf("\n");
    }
    printf("};\n");
}

int main(void) {
    read_pico8();
    print_palettes("game_bg_palettes", sizeof(bg_palettes), bg_palettes);
    print_palettes("game_obj_palettes", sizeof(obj_palettes), obj_palettes);
    return 0;
}
