#include "gen.h"

int main(void) {
    read_pico8();
    printf("section \"game_attrs\", rom0, align[8]");
    uint8_t *data = &pico8_data[0x3000];
    for (size_t i = 0; i < 128; i += 1, data += 1) {
        if (i % 16 == 0) {
            printf("\ndb ");
        } else {
            printf(",");
        }
        uint8_t attr = tile_palettes[i]->index;
        attr |= (*data & 0x01) << 3; // solid
        attr |= (*data & 0x10) << 0; // ice
        printf("$%02x", attr);
    }
    printf("\n");
    return 0;
}
