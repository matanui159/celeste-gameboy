include "hardware.inc"

section "map_rom", rom0


; (pos: b, tile: c)
load_tile::
    ld h, high(map)
    ld l, b
    ld [hl], c
    ld h, high(startof("game_attrs"))
    ld l, c
    ld a, [hl]
    and a, $07
    ld h, high(map_attr)
    ld l, b
    ld [hl], a
    ret


; (tile_pos: b) => bc
tile2obj_position::
    ; both rra operations assume C=0 from previous instruction
    ld a, b
    and a, $f0
    rra
    ld c, a
    ld a, b
    and a, $0f
    swap a
    rra
    ld b, a
    ret


; (map_id: a) => void
load_map::
    ; load each tile
    add a, high(startof("game_maps"))
    ld h, a
    ld l, $00
.loop:
    ld c, [hl]
    ld b, l
    push bc
    push hl
    call load_game_tile
    pop hl
    pop bc
    inc l
    jr nz, .loop
    ret


; (src: bc) => void <src_end: bc>
copy_map:
    ld hl, _SCRN0
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
; TODO: show map during H-blank in one frame
show_map::
    ; TODO: not sure if this is a nice spot for it...
    call draw_objects
    ld bc, map
    call copy_map
    ldh a, [engine_boot]
    cp a, BOOTUP_A_CGB
    ret nz
    ; CGB attributes
    ld a, 1
    ldh [rVBK], a
    call copy_map
    xor a, a
    ldh [rVBK], a
    ret


; () => void
init_map::
    xor a, a
    call load_map
    call show_map
    ld a, LCDCF_BGON | LCDCF_OBJON | LCDCF_BG8000 | LCDCF_ON
    ldh [rLCDC], a
    ret


section "map_wram", wram0, align[8]
map: ds $100
map_attr: ds $100
