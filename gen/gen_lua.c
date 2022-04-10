#include "gen.h"

static const char lookup_table[] = "\n 0123456789abcdefghijklmnopqrstuvwxyz!#%(){}[]<>+=/*:;.,~_";
static char lua_window[3153];

static char *slide_window(size_t size) {
    size_t move = sizeof(lua_window) - size;
    memmove(lua_window, &lua_window[size], move);
    return &lua_window[move];
}

int main(void) {
    gen_load();
    uint8_t *data = &gen_data[0x4300];
    int size = (data[4] << 8) | data[5];
    data += 8;
    while (size > 0) {
        if (*data == 0x00) {
            data += 1;
            char c = (char)*(data++);
            printf("%c", c);
            *slide_window(1) = c;
            size -= 1;
        } else if (*data < 0x3c) {
            char c = lookup_table[*(data++) - 1];
            printf("%c", c);
            *slide_window(1) = c;
            size -= 1;
        } else {
            size_t offset = (data[0] - 0x3c) * 16 + (data[1] & 0xf);
            data += 1;
            size_t length = (*(data++) >> 4) + 2;
            char *src = &lua_window[sizeof(lua_window) - offset];
            printf("%.*s", (int)length, src);
            memcpy(slide_window(length), src - length, length);
            size -= length;
        }
    }
    return 0;
}
