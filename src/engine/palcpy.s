    .area _CODE
; void palcpy(ubyte reg, ubyte dst, const uint *src, ubyte size)
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
    ld b, a
    ld a, (hl-)
    ld l, (hl)
    ld h, a
    ; for (; size != 0; size -= 1)
    inc b
    jr 1$
0$:
    ; *reg = *(src++)
    ld a, (hl+)
    ldh (c), a
1$:
    ; continue
    dec b
    jr nz, 0$
    ; return
    pop hl
    add sp, #3
    jp (hl)
