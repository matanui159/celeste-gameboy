#include "gen.h"

int main(void) {
    gen_load();
    printf("section \"Generated attributes\", romx, bank[1], align[8]\n");
    printf("GenAttrs::");
    uint8_t *data = &gen_data[0x3000];
    for (size_t i = 0; i < 128; i += 1, data += 1) {
        if (i % 16 == 0) {
            printf("\n    db ");
        } else {
            printf(", ");
        }
        uint8_t attr = gen_tile_palettes[i]->index;
        attr |= (*data & 0x01) << 3; // solid
        attr |= (*data & 0x10) << 0; // ice
        printf("$%02x", attr);
    }
    printf("\n");
    return 0;
}
