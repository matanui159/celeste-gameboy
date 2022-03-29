include "util.inc"
include "input.inc"

section "player_rom", rom0


; (pos: l) => void
player_load::
    call tile_get_pos
    ld hl, object_player
    LDA [hl+], c
    LDA [hl+], b
    LDA [hl+], 1
    LDZ [hl+]
    ret


; () => void
player_update::
    ; -- move
    LDW hl, spd_x
    ld bc, 1.0 >>8
    LD16 de, hl
    ABS16 de
    JRL16 bc, de, .deccel

    ; accel
    ld de, 0.6 >>8
    ld a, [input]
    bit INPUT_LEFT, a
    jr z, .noleft
    NEG16 bc
    jr .move
.noleft:
    bit INPUT_RIGHT, a
    jr nz, .move
    ld bc, 0
    jr .move

.deccel:
    ld de, 0.15 >>8
    JRP16 hl, .move
    NEG16 bc

.move:
    call accel
    STW spd_x, hl

    ; speed X
    LDA b, [object_player + OAM_X]
    LDA c, [rem_x]
    add hl, bc
    LDA [object_player + OAM_X], h
    LDA [rem_x], l
    ret


section "player_wram", wram0
spd_x: dw
rem_x: db
