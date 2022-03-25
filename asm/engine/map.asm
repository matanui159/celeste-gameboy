include "../hardware.inc"

section "map_rom", rom0


; (pos: b, tile: d)
init_tile::
    ld h, high(map)
    ld l, b
    ld [hl], d
    ld h, high(startof("game_attrs"))
    ld l, d
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
init_map::
    ; load each tile
    add a, high(startof("game_maps"))
    ld h, a
    ld l, $00
.loop:
    ld c, [hl]
    ld b, l
    ; get the init callback
    push hl
    ld h, high(startof("game_callbacks"))
    ld l, c
    ld d, $00
    ld e, [hl]
    sla e
    ld hl, init_callbacks
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ; call init
    ld d, c
    rst $00 ; call hl

    pop hl
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
; TODO: we either need to get rid of this function or come up with a better name
init_map_system::
    xor a, a
    call init_map
    call show_map
    ld a, LCDCF_BGON | LCDCF_OBJON | LCDCF_BG8000 | LCDCF_ON
    ldh [rLCDC], a
    ret


section "map_wram", wram0, align[8]
map: ds $100
map_attr: ds $100
