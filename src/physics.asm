include "reg.inc"
include "util.inc"

; () => %z
macro CP_FLAG
    push bc
    call tile_get_attr
    ; get flag from stack
    ld hl, sp+3
    ld b, [hl]
    and a, b
    pop bc
endm

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


; (pos: bc, flag: a) => %nz
tile_flag_at:
    ; TODO: this can definitely be optimized lol
    push af
    ; top-left
    ; player hitbox has an offset of 1, 3
    inc b
    inc c
    inc c
    inc c
    call tilepos_from_object
    ld e, l
    CP_FLAG
    jr nz, .return

    ; top-right
    ld a, b
    add a, 6 - 1
    ld b, a
    call tilepos_from_object
    ld a, l
    cp a, e
    jr z, .bottom
    ld e, l
    CP_FLAG
    jr nz, .return

    ; bottom-right
    ld a, c
    add a, 5 - 1
    ld c, a
    call tilepos_from_object
    ld a, l
    cp a, e
    jr z, .return
    CP_FLAG
    jr nz, .return

    ; bottom-left
    ld a, b
    sub a, 6 - 1
    ld b, a
    call tilepos_from_object
    CP_FLAG

.return:
    ; pop af into bc so we don't override flags
    pop bc
    ret

.bottom:
    ; bottom (edge case with no left/right difference)
    ld a, c
    add a, 5 - 1
    ld c, a
    call tilepos_from_object
    ld a, l
    cp a, e
    jr z, .return
    CP_FLAG
    jr .return


; (pos: bc) => %nz
solid_at:
    ld a, $08
    jp tile_flag_at


; (amount: a) => void
move_x:
    ld d, a
    MV8 b, [object_player + OAM_X]
    MV8 c, [object_player + OAM_Y]
    JRN8 d, .neg

    ; d > 0
.pos:
    inc b
    push bc
    push de
    call solid_at
    pop de
    pop bc
    jr nz, .pos_solid
    dec d
    jr nz, .pos
    jr .return

.pos_solid:
    dec b
.solid:
    MV0 [rem_x]
    ld hl, 0
    ST16 player_spd_x, hl
.return:
    MV8 [object_player + OAM_X], b
    ret

    ; d < 0
.neg:
    dec b
    push bc
    push de
    call solid_at
    pop de
    pop bc
    jr nz, .neg_solid
    inc d
    jr nz, .neg
    jr .return

.neg_solid:
    inc b
    jr .solid


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
