#include "gen.h"

static void print_tiles(
    const char *section,
    int get_index(const gen_palette_t *pal, uint8_t p8)
) {
    printf("section \"%s\", rom0\n", section);
    for (size_t i = 0; i < 128; i += 1) {
        const gen_palette_t *pal = tile_palettes[i];
        size_t tile_x = i % 16;
        size_t tile_y = i / 16;
        uint8_t *data = &pico8_data[(tile_y * 128 + tile_x) * 4];
        printf("dw `");
        for (size_t y = 0; y < 8; y += 1) {
            if (y > 0) {
                printf(",`");
            }
            for (size_t x = 0; x < 4; x += 1) {
                printf(
                    "%i%i",
                    get_index(pal, data[x] & 0xf),
                    get_index(pal, data[x] >> 4)
                );
            }
            data += 64;
        }
        printf("\n");
    }
}

static int get_cgb_index(const gen_palette_t *pal, uint8_t p8) {
    return pal->indices[p8];
}

static int get_dmg_index(const gen_palette_t *pal, uint8_t p8) {
    return pal->dmg_colors[get_cgb_index(pal, p8)];
}

int main(void) {
    load_pico8();
    print_tiles("game_dmg_tiles", get_dmg_index);
    print_tiles("game_cgb_tiles", get_cgb_index);
    return 0;
}
