section "player_rom", rom0


; (pos: bc, tile: d, attr: e) => void
update_player:
    ret


; (pos: b, tile: c) => void
create_player::
    ld d, c
    call tile2obj_position
    ld e, $00
    ld hl, update_player
    push hl
    call alloc_object
    pop hl
    ret
