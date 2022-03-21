section "player_rom", rom0


; (pos: bc, tile: d, attr: e) => void
update_player::
    inc b
    dec c
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
