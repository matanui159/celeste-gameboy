    .area _CODE
; void map_hblank(ubyte *map, ubyte tile, ubyte attr)
_map_hblank::
    ; ubyte attr
    ldhl sp, #2
    ld b, (hl)
    ; _Bool cgb = crt_boot == CRT_BOOT_CGB
    ld c, a
    ldh a, (0x80)
    cp a, #0x11
    ld a, c
    ; hbyte *vbank = &cgb_vbank
    ld c, #0x4f
    ; gb_if &= ~GB_INT_STAT
    ld hl, #0xff0f
    res 1, (hl)
    ; gb_halt()
    halt
    nop
    ; *map = tile
    ld (de), a
    ; if (cgb)
    jr nz, 0$
    ; *vbank = 1
    ld a, #1
    ldh (c), a
    ; *map = attr
    ld a, b
    ld (de), a
    ; *vbank = 0
    xor a, a
    ldh (c), a
0$:
    ; return
    pop hl
    add sp, #1
    jp (hl)
