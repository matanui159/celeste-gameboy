#include "gen.h"
#include <math.h>

#define SFX_CHAN_PULSE0 0
#define SFX_CHAN_PULSE1 1
#define SFX_CHAN_WAVE   2
#define SFX_CHAN_NOISE  3

#define SFX_PULSE_25 0x40
#define SFX_PULSE_50 0x80
#define SFX_WAVE_TRI 0x00
#define SFX_WAVE_SAW 0x40
#define SFX_WAVE_ORG 0x80

#define SFX_TRI    0x01
#define SFX_TILT   0x02
#define SFX_SAW    0x04
#define SFX_SQUARE 0x08
#define SFX_PULSE  0x10
#define SFX_ORG    0x20
#define SFX_NOISE  0x40
#define SFX_PHA    0x80

typedef struct sfx_sound_t {
    uint8_t channel;
    uint8_t waves;
} sfx_sound_t;

static const sfx_sound_t sfx_sounds[64] = {
    {
        //  0: player death
        SFX_CHAN_PULSE1 | SFX_PULSE_50,
        SFX_SQUARE | SFX_PULSE
    },
    {
        //  1: normal jump
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI
    },
    {
        //  2: wall jump
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI
    },
    {
        //  3: dash
        SFX_CHAN_NOISE,
        SFX_PULSE | SFX_NOISE
    },
    {
        //  4: player spawn jump
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI
    },
    {
        //  5: player spawn fall
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_PHA
    },
    {
        //  6: balloon collect
        SFX_CHAN_WAVE | SFX_WAVE_SAW,
        SFX_TILT
    },
    {
        //  7: balloon respawn 
        SFX_CHAN_WAVE | SFX_WAVE_SAW,
        SFX_TILT
    },
    {
        //  8: spring
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI
    },
    {
        //  9: out of dashes
        SFX_CHAN_NOISE,
        SFX_TILT | SFX_NOISE
    },
    {
        // 10: music 00, channel 2
        SFX_CHAN_NOISE,
        SFX_NOISE
    },
    {
        // 11: music 03, channel 2
        SFX_CHAN_PULSE0 | SFX_PULSE_50,
        SFX_TRI
    },
    {
        // 12: music 01, channel 3
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI
    },
    {
        // 13: fruit collect
        SFX_CHAN_WAVE | SFX_WAVE_ORG,
        SFX_ORG
    },
    {
        // 14: fruit flying away
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_PHA
    },
    {
        // 15: fall floor breaking
        SFX_CHAN_NOISE,
        SFX_NOISE
    },
    {
        // 16: fruit found (fake wall and chest)
        SFX_CHAN_PULSE1 | SFX_PULSE_50,
        SFX_SQUARE
    },
    {
        // 17: music 07, channel 2
        SFX_CHAN_PULSE0 | SFX_PULSE_50,
        SFX_ORG
    },
    {
        // 18: music 04, channel 3
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI
    },
    {
        // 19: music 04, channel 2
        SFX_CHAN_PULSE0 | SFX_PULSE_50,
        SFX_TRI
    },
    {
        // 20: music 04, channel 1
        SFX_CHAN_NOISE,
        SFX_NOISE
    },
    {
        // 21: music 00, channel 1
        SFX_CHAN_PULSE0 | SFX_PULSE_50,
        SFX_TILT
    },
    {
        // 22: music 01, channel 2
        SFX_CHAN_PULSE0 | SFX_PULSE_25,
        SFX_PHA
    },
    {
        // 23: key collect
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_PHA
    },
    {
        // 24: music 10, channel 1
        SFX_CHAN_PULSE0 | SFX_PULSE_25,
        SFX_PULSE
    },
    {
        // 25: music 10, channel 2
        SFX_CHAN_WAVE | SFX_WAVE_ORG,
        SFX_ORG
    },
    {
        // 26: music 10, channel 3
        SFX_CHAN_NOISE,
        SFX_NOISE
    },
    {
        // 27: music 12, channel 2
        SFX_CHAN_PULSE0 | SFX_PULSE_25,
        SFX_PULSE
    },
    {
        // 28: music 12, channel 1
        SFX_CHAN_WAVE | SFX_WAVE_ORG,
        SFX_ORG
    },
    {
        // 29: music 13, channel 1
        SFX_CHAN_WAVE | SFX_WAVE_ORG,
        SFX_ORG
    },
    {
        // 30: music 16, channel 1
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI | SFX_PHA
    },
    {
        // 31: music 14, channel 1
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI | SFX_PHA
    },
    {
        // 32: music 17, channel 1
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI | SFX_PHA
    },
    {
        // 33: music 14, channel 2
        SFX_CHAN_PULSE0 | SFX_PULSE_50,
        SFX_SQUARE
    },
    {
        // 34: music 16, channel 3
        SFX_CHAN_PULSE0 | SFX_PULSE_50,
        SFX_SQUARE
    },
    {
        // 35: unused?
        0, 0
    },
    {
        // 36: music 17, channel 3
        SFX_CHAN_PULSE0 | SFX_PULSE_50,
        SFX_SQUARE
    },
    {
        // 37: opening big chest
        SFX_CHAN_PULSE1 | SFX_PULSE_50,
        SFX_SQUARE
    },
    {
        // 38: start game
        SFX_CHAN_PULSE1 | SFX_PULSE_25,
        SFX_SAW
    },
    {
        // 39: music 20, channel 2
        SFX_CHAN_NOISE,
        SFX_NOISE
    },
    {
        // 40: unused?
        0, 0
    },
    {
        // 41: music 20, channel 3
        SFX_CHAN_WAVE | SFX_WAVE_ORG,
        SFX_ORG
    },
    {
        // 42: music 20, channel 1
        SFX_CHAN_PULSE0 | SFX_PULSE_25,
        SFX_SAW
    },
    {
        // 43: music 22, channel 2
        SFX_CHAN_PULSE0 | SFX_PULSE_25,
        SFX_SAW
    },
    {
        // 44: music 23, channel 3
        SFX_CHAN_WAVE | SFX_WAVE_ORG,
        SFX_ORG
    },
    {
        // 45: music 26, channel 2
        SFX_CHAN_PULSE0 | SFX_PULSE_25,
        SFX_SAW
    },
    {
        // 46: music 26, channel 1
        SFX_CHAN_NOISE,
        SFX_NOISE
    },
    {
        // 47: music 22, channel 1
        SFX_CHAN_NOISE,
        SFX_NOISE
    },
    {
        // 48: music 26, channel 3
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI
    },
    {
        // 49: music 27, channel 2
        SFX_CHAN_WAVE | SFX_WAVE_ORG,
        SFX_ORG
    },
    {
        // 50: music 28, channel 2
        SFX_CHAN_WAVE | SFX_WAVE_ORG,
        SFX_ORG
    },
    {
        // 51: orb collect
        SFX_CHAN_PULSE1 | SFX_PULSE_50,
        SFX_SQUARE | SFX_ORG | SFX_PHA
    },
    {
        // 52: music 27, channel 1
        SFX_CHAN_PULSE0 | SFX_PULSE_25,
        SFX_SAW
    },
    {
        // 53: music 28, channel 1
        SFX_CHAN_PULSE0 | SFX_PULSE_25,
        SFX_SAW
    },
    {
        // 54: landing dash recharge
        SFX_CHAN_WAVE | SFX_WAVE_ORG,
        SFX_SQUARE | SFX_ORG
    },
    {
        // 55: game end (flag)
        SFX_CHAN_PULSE1 | SFX_PULSE_50,
        SFX_SQUARE
    },
    {
        // 56: music 40, channel 1
        SFX_CHAN_PULSE0 | SFX_PULSE_50,
        SFX_ORG
    },
    {
        // 57: music 41, channel 1
        SFX_CHAN_PULSE0 | SFX_PULSE_50,
        SFX_ORG
    },
    {
        // 58: music 40, channel 2
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI
    },
    {
        // 59: music 41, channel 2
        SFX_CHAN_WAVE | SFX_WAVE_TRI,
        SFX_TRI
    },
    {
        // 60: music 40, channel 3
        SFX_CHAN_NOISE,
        SFX_NOISE
    },
    {
        // 61: music 30, channel 1
        SFX_CHAN_NOISE,
        SFX_NOISE
    },
    {
        // 62: music 33, channel 2
        SFX_CHAN_PULSE0 | SFX_PULSE_25,
        SFX_SAW
    },
    {
        // 63: unused
        0, 0
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

static float sfx_get_freq(uint8_t pitch) {
    return 444.0f * powf(2.0f, (pitch - 33) / 12.0f);
}

static sfx_note_t sfx_get_note(uint8_t *data, const sfx_sound_t *sound) {
    uint16_t raw = (data[0] << 0) | (data[1] << 8);
    sfx_note_t note;
    note.freq = sfx_get_freq(raw & 0x003f);
    note.wave = (raw & 0x01c0) >> 6;
    if (sound->waves & (1 << note.wave)) {
        note.volume = (raw & 0x0e00) >> 9;
    } else {
        note.volume = 0;
    }
    note.effect = sfx_effects[(raw & 0x7000) >> 12];
    return note;
}

static uint8_t sfx_get_length(uint8_t *data, const sfx_sound_t *sound) {
    data += 64;
    for (uint8_t length = 32; length > 0; length -= 1) {
        data -= 2;
        sfx_note_t note = sfx_get_note(data, sound);
        if (note.volume > 0) {
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
    printf("    dw $%04x\n", (freq << 0) | (note->effect << 11) | (note->volume << 13));
}

static void sfx_gen_wave(sfx_note_t *note) {
    uint16_t freq = 2048.0f - 65536.0f / note->freq;
    uint8_t volume = sfx_wave_volumes[note->volume];
    printf("    dw $%04x\n", (freq << 0) | (volume << 13));
}

static void sfx_gen_noise(sfx_note_t *note) {
    float freq = note->freq / sfx_get_freq(63) * 22050.0f;
    uint16_t div = 262144.0f / freq;
    uint8_t shift = 0;
    while (div > 7) {
        div >>= 1;
        shift += 1;
    }
    uint8_t poly = (div << 0) | (shift << 4);
    if ((1 << note->wave) != SFX_NOISE) {
        poly |= 0x08;
    }
    printf("    dw $%04x\n", (poly << 0) | (note->effect << 11) | (note->volume << 13));
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
        uint8_t flags = sound->channel;
        if (length == 0) {
            length = sfx_get_length(data, sound);
        } else {
            flags |= 0x04;
        }
        printf("    db $%02x, %u, %u\n", flags, speed, length);
        for (uint8_t j = 0; j < length; j += 1, data += 2) {
            sfx_note_t note = sfx_get_note(data, sound);
            if (note.volume == 0) {
                sfx_gen_none();
                continue;
            }
            switch (sound->channel & 0x03) {
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
            }
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
