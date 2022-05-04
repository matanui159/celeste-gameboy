#include "gen.h"

int main(void) {
    gen_load();
    FILE *image = fopen("gen/celeste.p8.png", "rb");
    // Get the file size
    fseek(image, 0, SEEK_END);
    long file_length = ftell(image);
    fseek(image, 0, SEEK_SET);

    // PNG magic
    printf("section \"Wrapper header\", rom0[$0000]\n");
    printf("    db ");
    for (size_t i = 0; i < 8; i += 1) {
        printf("$%02x, ", fgetc(image));
    }

    // IDAT chunk
    uint32_t hdr_length = 0;
    for (size_t i = 0; i < 4; i += 1) {
        int c = fgetc(image);
        hdr_length = (hdr_length << 8) | c;
        printf("$%02x, ", c);
    }
    hdr_length += 20;
    for (uint32_t i = 12; i < hdr_length; i += 1) {
        printf("$%02x, ", fgetc(image));
    }

    // dmGB chunk
    uint32_t max_length = 8 * 0x4000;
    uint32_t gb_length = max_length - file_length - 12;
    for (size_t i = 0; i < 4; i += 1) {
        printf("$%02x, ", gb_length >> 24);
        gb_length <<= 8;
    }
    printf("$64, $6d, $47, $42\n");
    printf("\n");

    // Chunk footer
    uint32_t ftr_length = file_length - hdr_length + 4;
    uint16_t ftr_addr = 0x8000 - (ftr_length % 0x4000);
    int ftr_bank = 7 - ftr_length / 0x4000;
    for (int i = ftr_bank; i < 8; i += 1) {
        printf("section \"Wrapper footer %i\", romx[$%04x], bank[%i]\n", i, ftr_addr, i);
        printf("    db ");
        for (uint16_t j = ftr_addr; j < 0x8000; j += 1) {
            if (j > ftr_addr) {
                printf(", ");
            }
            if (i == ftr_bank && j < ftr_addr + 4) {
                printf("$00");
            } else {
                printf("$%02x", fgetc(image));
            }
        }
        printf("\n");
        ftr_addr = 0x4000;
    }
    return 0;
}
