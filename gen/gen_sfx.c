#include "gen.h"
#include <math.h>

#define SFX_PULSE0_50 0x2
#define SFX_PULSE0_75 0x3
#define SFX_PULSE1_50 (SFX_PULSE0_50 | 0x4)
#define SFX_PULSE1_75 (SFX_PULSE0_75 | 0x4)
#define SFX_WAVE_TRI  0x8
#define SFX_WAVE_SAW  0x9
#define SFX_WAVE_ORG  0xa
#define SFX_NOISE     0xc

#define SFX_CHAN2(a, b) (((a) << 4) | ((b) << 0))
#define SFX_CHAN1(a)    SFX_CHAN2(a, a)
#define SFX_CHAN0       SFX_CHAN2(0, 0)

typedef struct sfx_sound_t {
    uint8_t channels;
    uint8_t waves[8]; // 0=none, 1=first, 2=second
} sfx_sound_t;

static const sfx_sound_t sfx_sounds[64] = {
    {
        //  0: player death
        SFX_CHAN1(SFX_PULSE1_50),
        {0, 0, 0, 1, 1, 0, 0, 0}
    },
    {
        //  1: normal jump
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        //  2: wall jump
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        //  3: dash
        SFX_CHAN2(SFX_PULSE1_75, SFX_NOISE),
        {0, 0, 0, 0, 1, 0, 2, 0}
    },
    {
        //  4: player spawn jump
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        //  5: player spawn fall
        SFX_CHAN1(SFX_WAVE_TRI),
        {0, 0, 0, 0, 0, 0, 0, 1}
    },
    {
        //  6: balloon collect
        SFX_CHAN1(SFX_WAVE_SAW),
        {0, 1, 0, 0, 0, 0, 0, 0}
    },
    {
        //  7: balloon respawn 
        SFX_CHAN1(SFX_WAVE_SAW),
        {0, 1, 0, 0, 0, 0, 0, 0}
    },
    {
        //  8: spring
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        //  9: out of dashes
        SFX_CHAN2(SFX_WAVE_SAW, SFX_NOISE),
        {0, 1, 0, 0, 0, 0, 2, 0}
    },
    {
        // 10: music 00, channel 2
        SFX_CHAN1(SFX_NOISE),
        {0, 0, 0, 0, 0, 0, 1, 0}
    },
    {
        // 11: music 03, channel 2
        SFX_CHAN1(SFX_PULSE0_50),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        // 12: music 01, channel 3
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        // 13: fruit collect
        SFX_CHAN1(SFX_WAVE_ORG),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 14: fruit flying away
        SFX_CHAN1(SFX_WAVE_TRI),
        {0, 0, 0, 0, 0, 0, 0, 1}
    },
    {
        // 15: fall floor breaking
        SFX_CHAN1(SFX_NOISE),
        {0, 0, 0, 0, 0, 0, 1, 0}
    },
    {
        // 16: fruit found (fake wall and chest)
        SFX_CHAN1(SFX_PULSE1_50),
        {0, 0, 0, 1, 0, 0, 0, 0}
    },
    {
        // 17: music 07, channel 2
        SFX_CHAN1(SFX_PULSE0_50),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 18: music 04, channel 3
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        // 19: music 04, channel 2
        SFX_CHAN1(SFX_PULSE1_50),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        // 20: music 04, channel 1
        SFX_CHAN1(SFX_NOISE),
        {0, 0, 0, 0, 0, 0, 1, 0}
    },
    {
        // 21: music 00, channel 1
        SFX_CHAN1(SFX_PULSE0_50),
        {0, 1, 0, 0, 0, 0, 0, 0}
    },
    {
        // 22: music 01, channel 2
        SFX_CHAN1(SFX_PULSE0_75),
        {0, 0, 0, 0, 0, 0, 0, 1}
    },
    {
        // 23: key collect
        SFX_CHAN1(SFX_WAVE_TRI),
        {0, 0, 0, 0, 0, 0, 0, 1}
    },
    {
        // 24: music 10, channel 1
        SFX_CHAN1(SFX_PULSE0_75),
        {0, 0, 0, 0, 1, 0, 0, 0}
    },
    {
        // 25: music 10, channel 2
        SFX_CHAN1(SFX_WAVE_ORG),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 26: music 10, channel 3
        SFX_CHAN1(SFX_NOISE),
        {0, 0, 0, 0, 0, 0, 1, 0}
    },
    {
        // 27: music 12, channel 2
        SFX_CHAN1(SFX_PULSE0_75),
        {0, 0, 0, 0, 1, 0, 0, 0}
    },
    {
        // 28: music 12, channel 1
        SFX_CHAN1(SFX_WAVE_ORG),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 29: music 13, channel 1
        SFX_CHAN1(SFX_WAVE_ORG),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 30: music 16, channel 1
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 1}
    },
    {
        // 31: music 14, channel 1
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 1}
    },
    {
        // 32: music 17, channel 1
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 1}
    },
    {
        // 33: music 14, channel 2
        SFX_CHAN1(SFX_PULSE0_50),
        {0, 0, 0, 1, 0, 0, 0, 0}
    },
    {
        // 34: music 16, channel 3
        SFX_CHAN1(SFX_PULSE0_50),
        {0, 0, 0, 1, 0, 0, 0, 0}
    },
    {
        // 35: unused?
        SFX_CHAN0,
        {0, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        // 36: music 17, channel 3
        SFX_CHAN1(SFX_PULSE0_50),
        {0, 0, 0, 1, 0, 0, 0, 0}
    },
    {
        // 37: opening big chest
        SFX_CHAN1(SFX_PULSE1_50),
        {0, 0, 0, 1, 0, 0, 0, 0}
    },
    {
        // 38: start game
        SFX_CHAN1(SFX_PULSE1_75),
        {0, 0, 1, 0, 0, 0, 0, 0}
    },
    {
        // 39: music 20, channel 2
        SFX_CHAN1(SFX_NOISE),
        {0, 0, 0, 0, 0, 0, 1, 0}
    },
    {
        // 40: unused?
        SFX_CHAN0,
        {0, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        // 41: music 20, channel 3
        SFX_CHAN1(SFX_WAVE_ORG),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 42: music 20, channel 1
        SFX_CHAN1(SFX_PULSE0_75),
        {0, 0, 1, 0, 0, 0, 0, 0}
    },
    {
        // 43: music 22, channel 2
        SFX_CHAN1(SFX_PULSE0_75),
        {0, 0, 1, 0, 0, 0, 0, 0}
    },
    {
        // 44: music 23, channel 3
        SFX_CHAN1(SFX_WAVE_ORG),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 45: music 26, channel 2
        SFX_CHAN1(SFX_PULSE0_75),
        {0, 0, 1, 0, 0, 0, 0, 0}
    },
    {
        // 46: music 26, channel 1
        SFX_CHAN1(SFX_NOISE),
        {0, 0, 0, 0, 0, 0, 1, 0}
    },
    {
        // 47: music 22, channel 1
        SFX_CHAN1(SFX_NOISE),
        {0, 0, 0, 0, 0, 0, 1, 0}
    },
    {
        // 48: music 26, channel 3
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        // 49: music 27, channel 2
        SFX_CHAN1(SFX_WAVE_ORG),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 50: music 28, channel 2
        SFX_CHAN1(SFX_WAVE_ORG),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 51: orb collect
        SFX_CHAN2(SFX_WAVE_TRI, SFX_PULSE1_50),
        {0, 0, 0, 2, 0, 0, 0, 1}
    },
    {
        // 52: music 27, channel 1
        SFX_CHAN1(SFX_PULSE0_75),
        {0, 0, 1, 0, 0, 0, 0, 0}
    },
    {
        // 53: music 28, channel 1
        SFX_CHAN1(SFX_PULSE0_75),
        {0, 0, 1, 0, 0, 0, 0, 0}
    },
    {
        // 54: landing dash recharge
        SFX_CHAN2(SFX_PULSE1_50, SFX_WAVE_ORG),
        {0, 0, 0, 1, 0, 2, 0, 0}
    },
    {
        // 55: game end (flag)
        SFX_CHAN1(SFX_PULSE1_50),
        {0, 0, 0, 1, 0, 0, 0, 0}
    },
    {
        // 56: music 40, channel 1
        SFX_CHAN1(SFX_PULSE0_50),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 57: music 41, channel 1
        SFX_CHAN1(SFX_PULSE0_50),
        {0, 0, 0, 0, 0, 1, 0, 0}
    },
    {
        // 58: music 40, channel 2
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        // 59: music 41, channel 2
        SFX_CHAN1(SFX_WAVE_TRI),
        {1, 0, 0, 0, 0, 0, 0, 0}
    },
    {
        // 60: music 40, channel 3
        SFX_CHAN1(SFX_NOISE),
        {0, 0, 0, 0, 0, 0, 1, 0}
    },
    {
        // 61: music 30, channel 1
        SFX_CHAN1(SFX_NOISE),
        {0, 0, 0, 0, 0, 0, 1, 0}
    },
    {
        // 62: music 33, channel 2
        SFX_CHAN1(SFX_PULSE0_75),
        {0, 0, 1, 0, 0, 0, 0, 0}
    },
    {
        // 63: unused
        SFX_CHAN0,
        {0, 0, 0, 0, 0, 0, 0, 0}
    }
};

static uint8_t sfx_effects[8] = {0, 1, 0, 0, 2, 3, 0, 0};
static uint8_t sfx_wave_volumes[8] = {0, 3, 3, 2, 2, 2, 1, 1};

typedef struct sfx_note_t {
    float freq;
    uint8_t wave;
    uint8_t volume;
    uint8_t effect;
} sfx_note_t;

static sfx_note_t sfx_get_note(uint8_t *data, const sfx_sound_t *sound) {
    uint16_t raw = (data[0] << 0) | (data[1] << 8);
    sfx_note_t note;
    note.freq = 440.0f * powf(2.0f, ((raw & 0x003f) - 33) / 12.0f);
    note.wave = sound->waves[(raw & 0x01c0) >> 6];
    note.volume = (raw & 0x0e00) >> 9;
    note.effect = sfx_effects[(raw & 0x7000) >> 12];
    if (note.volume == 0) {
        note.wave = 0;
    }
    return note;
}

static uint8_t sfx_get_length(uint8_t *data, const sfx_sound_t *sound) {
    data += 64;
    for (uint8_t length = 32; length > 0; length -= 1) {
        data -= 2;
        sfx_note_t note = sfx_get_note(data, sound);
        if (note.wave != 0) {
            return length;
        }
    }
    return 0;
}

static void sfx_gen_none(void) {
    printf("    dw $0000\n");
}

static void sfx_gen_pulse(sfx_note_t *note) {
    uint16_t freq = 2048.0f - 131072.0f / note->freq;
    printf("    dw $%04x\n", (freq >> 1) | (note->effect << 10) | ((note->wave - 1) << 12) | (note->volume << 13));
}

static void sfx_gen_wave(sfx_note_t *note) {
    uint16_t freq = 2048.0f - 65536.0f / note->freq;
    uint8_t volume = sfx_wave_volumes[note->volume];
    printf("    dw $%04x\n", (freq >> 1) | ((note->wave - 1) << 12) | (volume << 13));
}

static void sfx_gen_noise(sfx_note_t *note) {
    uint16_t div = 262144.0f / note->freq;
    uint8_t shift = 0;
    while (div > 7) {
        div >>= 1;
        shift += 1;
    }
    printf("    dw $%04x\n", (div << 0) | (shift << 4) | (note->effect << 10) | ((note->wave - 1) << 12) | (note->volume << 13));
}

int main(void) {
    gen_load();
    printf("section \"Generated sounds\", romx, bank[1]");
    for (size_t i = 0; i < 64; i += 1) {
        const sfx_sound_t *sound = &sfx_sounds[i];
        uint8_t *data = &gen_data[0x3200 + i * 68];
        printf("\nSound%02zu:\n", i);
        uint8_t speed = data[65];
        uint8_t length = data[67];
        uint8_t flags = 0x00;
        if (length == 0) {
            length = sfx_get_length(data, sound);
        } else {
            flags = 0x80;
        }
        printf("    db $%02x, $%02x, $%02x\n", sound->channels, speed, length | flags);
        for (uint8_t j = 0; j < length; j += 1) {
            sfx_note_t note = sfx_get_note(data, sound);
            uint8_t channel;
            switch (note.wave) {
            case 1:
                channel = sound->channels >> 4;
                break;
            case 2:
                channel = sound->channels & 0x0f;
                break;
            default:
                channel = 0x10;
                break;
            }
            switch (channel >> 2) {
            case 0:
            case 1:
                sfx_gen_pulse(&note);
                break;
            case 2:
                sfx_gen_wave(&note);
                break;
            case 3:
                sfx_gen_noise(&note);
                break;
            default:
                sfx_gen_none();
                break;
            }
            data += 2;
        }
    }

    printf("\nsection \"Generated sound table\", romx, bank[1], align[8]\n");
    printf("GenSoundTable::");
    for (size_t i = 0; i < 64; i += 1) {
        if (i % 8 == 0) {
            printf("\n    dw ");
        } else {
            printf(", ");
        }
        printf("Sound%02zu", i);
    }
    printf("\n");
    return 0;
}
