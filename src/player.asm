include "util.inc"
include "input.inc"

section "player_rom", rom0


; (pos: l) => void
player_load::
    call tilepos_to_object
    ld hl, object_player
    MV8 [hl+], c
    MV8 [hl+], b
    MV8 [hl+], 1
    MV0 [hl+]
    ret


; () => void
player_update::
    ; -- move
    LD16 hl, player_spd_x
    ld bc, 1.0 >>8
    MV16 de, hl
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
    JRP8 h, .move
    NEG16 bc

.move:
    call physics_accel
    ST16 player_spd_x, hl

    jp physics_move


section "player_wram", wram0
player_spd_x:: dw
