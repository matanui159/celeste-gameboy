#include "gen.h"

typedef char text_pair_t[2];

static uint8_t text_find_index(text_pair_t *pairs, const text_pair_t pr) {
    uint8_t i = 0;
    for (;; i += 1) {
        if (pairs[i][0] == pr[0] && pairs[i][1] == pr[1]) {
            return i;
        } else if (pairs[i][0] == '\0') {
            break;
        }
        assert(i != 255);
    }
    pairs[i][0] = pr[0];
    pairs[i][1] = pr[1];
    return i;
}

static void text_print_halfrow(uint8_t *font, uint8_t c, size_t y) {
    size_t tile_x = c % 16;
    size_t tile_y = c / 16;
    uint8_t *data = &font[((tile_y * 8 + y - 2) * 16 + tile_x) * 8];
    for (size_t x = 0; x < 4; x += 1) {
        // TODO: compress this data down to 1-bit per pixel
        printf(data[x] < 128 ? "0" : "3");
    }
}

int main(void) {
    gen_load();
    text_pair_t pairs[256];
    memset(pairs, 0, sizeof(pairs));
    // Insert in all numbers 00-99, and 0-9 with spaces
    for (int i = 0; i < 100; i += 1) {
        text_pair_t pr = {(i / 10) + '0', (i % 10) + '0'};
        text_find_index(pairs, pr);
    }
    for (int i = 0; i < 10; i += 1) {
        text_pair_t pr = {' ', i + '0'};
        text_find_index(pairs, pr);
    }

    printf("section \"Generated text\", romx, bank[1]\n");
    size_t line_count = sizeof(gen_text_lines) / sizeof(gen_text_t);
    for (size_t i = 0; i < line_count; i += 1) {
        const gen_text_t *text = &gen_text_lines[i];
        printf("%s::\n", text->name);
        printf("    db ");
        for (const char *line = text->text; *line != '\0'; line += 2) {
            if (line != text->text) {
                printf(", ");
            }
            uint8_t tile = text_find_index(pairs, line);
            printf("$%02x", (tile + 0x84) & 0xff);
        }
        printf("\n.end::\n");
    }

    int width, height;
    uint8_t *font = stbi_load("gen/pico8_font.png", &width, &height, NULL, 1);
    assert(font != NULL);
    printf("\nsection fragment \"Tiles\", romx, bank[1]\n");
    printf("GenText::");
    for (size_t i = 0; i < 256; i += 1) {
        char *pr = pairs[i];
        if (pr[0] == '\0') {
            break;
        }
        printf("\n");
        for (size_t y = 0; y < 8; y += 1) {
            printf("    dw `");
            text_print_halfrow(font, pr[0], y);
            text_print_halfrow(font, pr[1], y);
            printf("\n");
        }
    }
    return 0;
}
