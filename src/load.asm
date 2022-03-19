section "load_rom", rom0


; (pos: b, tile: c)
load_game_tile::
    ; jp load_tile
    push bc
    ; Setup return address
    ld hl, .return
    push hl
    ld a, c
    cp a, $01
    jp z, create_player
    ; Do default path without modified return address
    pop hl
    pop bc
    jp load_tile
.return:
    pop bc
    ld c, $00
    jp load_tile
