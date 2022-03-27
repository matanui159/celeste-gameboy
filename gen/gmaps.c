#include "gen.h"

int main(void) {
    read_pico8();
    printf("const unsigned char game_maps[] = {\n");
    for (size_t i = 0; i < 32; i += 1) {
        size_t map_x = i % 8;
        size_t map_y = i / 8;
        uint8_t *data = &pico8_data[(map_y * 128 + map_x) * 16];
        if (map_y < 2) {
            data += 0x2000;
        }
        printf("   ");
        for (size_t y = 0; y < 16; y += 1) {
            for (size_t x = 0; x < 16; x += 1) {
                printf(" 0x%02x,", data[x]);
            }
            data += 128;
        }
        printf("\n");
    }
    printf("};\n");
    return 0;
}
