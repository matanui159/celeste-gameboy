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


; (pos: bc) => a <pos: bc>
tile_flags_at:
    ; top-left
    ; player hitbox has an offset of 1, 3
    inc b
    inc c
    inc c
    inc c
    call tile_get_addr
    call tile_get_attr
    push af

    ; top-right
    ld a, b
    and a, $07
    ; hitbox width is 6, so no need to check if x%8 < 3
    cp a, 3
    jr c, .bottom
    inc l
    call tile_get_attr
    pop de
    or a, d
    push af

    ; bottom-right
    ld a, c
    and a, $07
    ; hitbox height is 5 so no need to check if y%8 < 4
    cp a, 4
    jr c, .return
    ld de, $20
    add hl, de
    call tile_get_attr
    pop de
    or a, d
    push af

    ; bottom-left
    dec l
    call tile_get_attr
    pop de
    or a, d
    push af

.return:
    ; reset position
    dec b
    dec c
    dec c
    dec c
    pop af
    ret

.bottom:
    ; bottom (edge case with no left/right difference)
    ld a, c
    and a, $07
    ; hitbox height is 5 so no need to check if y%8 < 4
    cp a, 4
    jr c, .return
    ld de, $20
    add hl, de
    call tile_get_attr
    pop de
    or a, d
    push af
    jr .return


; (amount: a) => void
move_x:
    ld d, a
    MV8 b, [object_player + OAM_X]
    MV8 c, [object_player + OAM_Y]
    JRN8 d, .neg

    ; d > 0
.pos:
    inc b
    push de
    call tile_flags_at
    pop de
    bit 3, a ; solid
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
    push de
    call tile_flags_at
    pop de
    bit 3, a ; solid
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
