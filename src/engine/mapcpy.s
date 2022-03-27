    .area _CODE
; void mapcpy(ubyte *dst, const ubyte *src)
_mapcpy::
    ; push(gb_ie, gb_stat)
    ldh a, (0xff)
    ld h, a
    ldh a, (0x41)
    ld l, a
    push hl
    ld h, d
    ld l, e
    ld d, b
    ld e, c
    ; for (ubyte x = 16; x != 0; x -= 1)
    ld b, #16
0$:
    ; *(dst++) = *(src++)
    ld a, (de)
    inc de
    ld (hl+), a
    ; continue
    dec b
    jr nz, 0$
    ; dst += 16
    ld c, #16
    add hl, bc
    ; gb_lcdc |= GB_LCDC_ENABLE
    ld c, #0x40
    ldh a, (c)
    or a, #0x80
    ldh (c), a
    ; gb_stat = GB_STAT_INT_HBLANK
    inc c
    ld a, #0x08
    ldh (c), a
    ; gb_ie = GB_INT_STAT
    ld a, #0x02
    ldh (0xff), a
    ; for (ubyte y = 15; y != 0; y -= 1)
    ld c, #15
1$:
    ; for (ubyte x = 16; x != 0; x -= 1)
    ld b, #16
2$:
    ; gb_if &= ~GB_INT_STAT
    ldh a, (0x0f)
    and a, #(~0x02)
    ldh (0x0f), a
    ; ubyte tile = *(src++)
    ld a, (de)
    inc de
    ; gb_halt()
    halt
    nop
    ; *(dst++) = tile
    ld (hl+), a
    ; continue
    dec b
    jr nz, 2$
    ; src += 16
    ld a, c
    ld c, #16
    add hl, bc
    ld c, a
    ; continue
    dec c
    jr nz, 1$
    ; pop(gb_ie, gb_stat)
    pop hl
    ld a, h
    ldh (0xff), a
    ld a, l
    ldh (0x41), a
    ; return
    ret
