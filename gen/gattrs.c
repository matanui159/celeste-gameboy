#include "gen.h"

int main(void) {
    read_pico8();
    printf("const unsigned char game_attrs[] = {");
    uint8_t *data = &pico8_data[0x3000];
    for (size_t i = 0; i < 128; i += 1, data += 1) {
        if (i % 16 == 0) {
            printf("\n   ");
        }
        uint8_t attr = tile_palettes[i]->index;
        attr |= (*data & 0x01) << 3; // solid
        attr |= (*data & 0x10) << 0; // ice
        printf(" 0x%02x,", attr);
    }
    printf("\n};\n");
    return 0;
}
