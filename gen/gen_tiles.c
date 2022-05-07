#include "gen.h"

static uint8_t tile_get_index(const gen_palette_t *pal, uint8_t color) {
    for (uint8_t i = 0; i < sizeof(pal->colors); i += 1) {
        if (pal->colors[i] == color) {
            return i & 0x3;
        }
    }
    return 0;
}

int main(void) {
    gen_load();
    printf("section fragment \"Tiles\", romx, bank[1]\n");
    printf("GenTiles::");
    for (size_t i = 0; i < 128; i += 1) {
        const gen_palette_t *pal = gen_tile_palettes[i];
        size_t tile_x = i % 16;
        size_t tile_y = i / 16;
        uint8_t *data = &gen_data[(tile_y * 128 + tile_x) * 4];
        printf("\n");
        for (size_t y = 0; y < 8; y += 1) {
            printf("    dw `");
            for (size_t x = 0; x < 4; x += 1) {
                printf(
                    "%i%i",
                    tile_get_index(pal, data[x] & 0xf),
                    tile_get_index(pal, data[x] >> 4)
                );
            }
            printf("\n");
            data += 64;
        }
    }
    return 0;
}
