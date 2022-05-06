#include "gen.h"

static const uint32_t palette_colors[] = {
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
static const uint8_t palette_shades[] = {
      0,   6,  12,  20,  28,  36,  45,  56,
     66,  76,  88, 100, 113, 125, 137, 149,
    161, 172, 182, 192, 202, 210, 218, 225,
    232, 238, 243, 247, 250, 252, 254, 255
};

static uint8_t palette_get_color(uint8_t shade) {
    uint8_t color;
    int dist = -1;
    for (size_t i = 0; i < sizeof(palette_shades); i += 1) {
        uint8_t new_dist = GEN_ABS(palette_shades[i] - shade);
        if (dist < 0 || new_dist < dist) {
            color = i;
            dist = new_dist;
        }
    }
    return color;
}

static void palettes_gen(
    const char *label,
    size_t palette_size,
    const gen_palette_t *palettes
) {
    printf("%s::\n", label);
    size_t palette_count = palette_size / sizeof(gen_palette_t);
    for (size_t p = 0; p < palette_count; p += 1) {
        const gen_palette_t *pal = &palettes[p];
        printf("    dw ");
        for (size_t c = 0; c < 4; c += 1) {
            if (c > 0) {
                printf(", ");
            }
            uint32_t pico8 = palette_colors[pal->colors[c]];
            uint8_t r = palette_get_color((pico8 >> 16) & 0xff);
            uint8_t g = palette_get_color((pico8 >>  8) & 0xff);
            uint8_t b = palette_get_color((pico8 >>  0) & 0xff);
            uint16_t cgb = (r << 0) | (g << 5) | (b << 10);
            printf("$%04x", cgb);
        }
        printf("\n");
    }
    printf(".end::\n");
}

int main(void) {
    gen_load();
    printf("section \"Generated palettes\", romx, bank[1]\n");
    palettes_gen("GenPalettesBG", sizeof(gen_bg_palettes), gen_bg_palettes);
    palettes_gen("GenPalettesOBJ", sizeof(gen_obj_palettes), gen_obj_palettes);
    palettes_gen("GenPalettesTitle", sizeof(gen_title_palettes), gen_title_palettes);
    return 0;
}
