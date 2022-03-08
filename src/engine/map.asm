section "map_rom", rom0


; (map_id: a) => void
load_map::
    ; copy the map to memory
    ld hl, map
    add a, high(celeste_maps)
    ld b, a
    ld c, 0
    ld de, map.end - map
    call memcpy

    ; copy over the palettes from the flags
    ld b, h
    ld c, l
    dec b
    ld d, high(celeste_flags)
.loop:
    ld a, [bc]
    ld e, a
    ld a, [de]
    and a, $07
    ld [hl+], a
    inc c
    jr nz, .loop
    ret


; (src: bc) => void <src_end: bc>
copy_map:
    ld hl, VRAM_TMAP
    ld de, $10
.loop:
    call memcpy
    ld de, $10
    add hl, de
    ld a, c
    cp a, 0
    jr nz, .loop
    ret    


; () => void
show_map::
    ld bc, map
    call copy_map
    ld a, 1
    ldh [REG_VBK], a
    call copy_map
    xor a, a
    ldh [REG_VBK], a
    ret


section "map_wram", wram0, align[8]
map::
    ds $100
.end:
map_attr:
    ds $100
