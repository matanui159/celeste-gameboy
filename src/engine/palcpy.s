    .area _CODE
; void palcpy(ubyte reg, ubyte dst, const uint *src, ubyte size);
_palcpy::
    ; *(reg++) = dst | CGB_PALETTE_INC
    ld c, a
    ld a, e
    set 7, a
    ldh (c), a
    inc c
    ; const uint *src, ubyte size
    ldhl sp, #4
    ld a, (hl-)
    or a, a
    jr z, 1$
    ld b, a
    ld a, (hl-)
    ld l, (hl)
    ld h, a
    ; for (; size != 0; size -= 1)
0$:
    ; *reg = *(src++)
    ld a, (hl+)
    ldh (c), a
    ld a, (hl+)
    ldh (c), a
    ; for (; size != 0; size -= 1)
    dec b
    jr nz, 0$
1$:
    pop hl
    add sp, #3
    jp (hl)
