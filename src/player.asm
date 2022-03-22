include "engine/input.inc"

section "player_rom", rom0


; (pos: bc, tile: d, attr: e) => void
update_player::
    ldh a, [input]
    bit INB_RIGHT, a
    jr z, .noright
    inc b
    inc b
.noright:
    bit INB_LEFT, a
    jr z, .noleft
    dec b
    dec b
.noleft:
    ldh a, [next_input]
    bit INB_UP, a
    jr z, .noup
    ld a, c
    sub a, 8
    ld c, a
.noup:
    ret


; (pos: b, tile: d) => void
init_player::
    push bc
    call tile2obj_position
    ld e, $00
    call alloc_object
    pop bc
    ld d, $00
    jp init_tile
