include "reg.inc"
include "util.inc"

section "physics_rom", rom0


; (value: hl, target: bc, accel: de) => void
physics_accel::
    ; This is called `appr` in the original source code
    ; Likely short for appreciate
    JRL16 hl, bc, .less
    SUB16 hl, de
    JRL16 hl, bc, .equal
.return:
    ret
.less:
    add hl, de
    JRL16 hl, bc, .return
.equal:
    MV16 hl, bc
    ret


; (amount: a) => void
move_x:
    ld hl, object_player + OAM_X
    ld d, [hl]
.loop:
    JRN8 a, .neg
    inc d
    dec a
    jr nz, .loop
    jr .return
.neg:
    dec d
    inc a
    jr nz, .loop
.return:
    ld [hl], d
    ret


; (spd_x: hl) => void
physics_move::
    ; -- [x] get move amount
    ld bc, rem_x
    ld d, 0
    MV8 e, [bc]
    add hl, de
    MV8 [bc], l

    ld a, h
    cp a, d
    call nz, move_x
    ret


section "physics_wram", wram0
rem_x: db
