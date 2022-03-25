#include "gen.h"

static void print_tiles(
    const char *name,
    uint8_t get_index(const gen_palette_t *pal, uint8_t p8)
) {
    printf("const unsigned char %s[] = {\n", name);
    for (size_t i = 0; i < 128; i += 1) {
        const gen_palette_t *pal = tile_palettes[i];
        size_t tile_x = i % 16;
        size_t tile_y = i / 16;
        uint8_t *data = &pico8_data[(tile_y * 128 + tile_x) * 4];
        printf("   ");
        for (size_t y = 0; y < 8; y += 1) {
            uint8_t lo = 0;
            uint8_t hi = 0;
            for (size_t x = 0; x < 4; x += 1) {
                uint8_t index = get_index(pal, data[x] & 0xf);
                lo = (lo << 1) | (index & 0x1);
                hi = (hi << 1) | (index >> 1);
                index = get_index(pal, data[x] >> 4);
                lo = (lo << 1) | (index & 0x1);
                hi = (hi << 1) | (index >> 1);
            }
            printf(" 0x%02x, 0x%02x,", lo, hi);
            data += 64;
        }
        printf("\n");
    }
    printf("};\n");
}

static uint8_t get_cgb_index(const gen_palette_t *pal, uint8_t p8) {
    return pal->indices[p8];
}

static uint8_t get_dmg_index(const gen_palette_t *pal, uint8_t p8) {
    return pal->dmg_colors[get_cgb_index(pal, p8)];
}

int main(void) {
    read_pico8();
    print_tiles("game_dmg_tiles", get_dmg_index);
    printf("\n");
    print_tiles("game_cgb_tiles", get_cgb_index);
    return 0;
}
