#include "gen.h"

static const uint8_t music_starts[] = {0, 10, 20, 30, 40};

static int music_is_end_frame(uint8_t *data) {
    return (data[1] & 0x80) != 0;
}

static int music_is_sound_enabled(uint8_t sound) {
    return (sound & 0x40) == 0;
}

int main(void) {
    gen_load();
    printf("section \"Generated music\", romx, bank[1]");
    for (size_t i = 0; i < sizeof(music_starts); i += 1) {
        uint8_t start = music_starts[i];
        uint8_t *data = &gen_data[0x3100 + (start - 1) * 4];
        printf("\nGenMusic%02u::\n", start);
        do {
            data += 4;
            printf("    db ");
            for (size_t j = 0; music_is_sound_enabled(data[j]); j += 1) {
                if (j > 0) {
                    printf(", ");
                }
                uint8_t sound = data[j] & 0x3f;
                if (!music_is_sound_enabled(data[j + 1])) {
                    sound |= 0x40;
                    if (music_is_end_frame(data)) {
                        sound |= 0x80;
                    }
                }
                printf("$%02x", sound);
            }
            printf("\n");
        } while(!music_is_end_frame(data));
    }
    return 0;
}
