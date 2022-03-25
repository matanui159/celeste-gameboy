include "engine/input.inc"

section "player_rom", rom0


; (pos: bc, tile: d, attr: e) => void
update_player::
    ; move acceleration
    push bc
    ld hl, spd_x
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld bc, $100
    ld de, 153
    call accel
    ld bc, spd_x
    ld a, l
    ld [bc], a
    inc c
    ld a, h
    ld [bc], a
    ; move speed
    pop bc
    ld d, c
    ldh a, [rem_x]
    ld c, a
    add hl, bc
    ld b, h
    ld a, l
    ldh [rem_x], a
    ld c, d
    ; animation
    ld d, $01
    ld e, $00
    ret


; (pos: b, tile: d) => void
init_player::
    push bc
    call tile2obj_position
    ld e, $00
    call alloc_object
    pop bc
    ld d, $00
    call init_tile
    ; reset memory
    xor a, a
    ld hl, spd_x
    ld [hl+], a
    ld [hl+], a
    ldh [rem_x], a
    ret


section "player_wram", wram0, align[1]
spd_x: dw

section "player_hram", hram
rem_x: db
