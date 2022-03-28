include "reg.inc"
include "util.inc"

section "player_rom", rom0


; (pos: l) => void
player_load::
    call tile_get_pos
    ld hl, object_player
    LDA [hl+], c
    LDA [hl+], b
    LDA [hl+], 1
    LDA [hl+], $00
    ret


; () => void
player_update::
    ld hl, object_player
    dec [hl]
    inc l
    inc [hl]
    ret
