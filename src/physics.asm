include "hardware.inc"

include "reg.inc"
include "util.inc"

section "Physics ROM", rom0


; Resets the physics variables
PhysicsLoad::
    xor a, a
    ldh [hPlayerRemX], a
    ret


;; Updates a value until it meets a target
;; This is called `appr` in the original source code, likely short for
;; appreciate.
;; Unlike the Lua verison of this code, this only updates in one direction.
;;
;; @param hl: Current value
;; @param bc: Target value
;; @param de: Rate to increase or decrease by
;; @returns hl: New value
PhysicsAccelerate::
    ; Add to the value
    add hl, de
    ; Do a 16-bit signed compare between the new value and the target value,
    ; store the result in A.
    ; As part of this compare we use DE to be H and B with the high bit inverted
    push de
    ld a, h
    xor a, $80
    ld d, a
    ld a, b
    xor a, $80
    ld e, a
    ld a, l
    sub a, c
    ld a, d
    sbc a, e
    rla
    ; Check the sign of DE to see if we are accelerating or deccelerating
    pop de
    bit 7, d
    jr nz, .deccelerate

    ; When accelerating we set the value to the target if it is larger than the
    ; target
    bit 0, a
    ret nz
    jr .equal

.deccelerate:
    ; When deccelerating we set the value to the target if it is smaller than
    ; the target
    bit 0, a
    ret z

.equal:
    ld h, b
    ld l, c
    ret


;; @param h: Amount
moveX:
    ld a, [wObjectPlayer + OAMA_X]
    add a, h
    ld [wObjectPlayer + OAMA_X], a
    ret


;; @param bc: Speed X
PhysicsMovePlayer::
    ; -- [x] get move amount --
    ; We add the remainder to the speed, and use the high byte to move the
    ; player. The low byte gets saved back as a remainder.
    ldh a, [hPlayerRemX]
    ld l, a
    ld h, 0
    add hl, bc
    ld a, l
    ldh [hPlayerRemX], a
    ; If it is non-zero, we move in the X direction
    ld a, h
    or a, a
    jp nz, moveX
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
    MV8 b, [wObjectPlayer + OAM_X]
    MV8 c, [wObjectPlayer + OAM_Y]
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
    MV0 [hPlayerRemX]
    ld hl, 0
    ST16 wPlayerSpeedX, hl
.return:
    MV8 [wObjectPlayer + OAM_X], b
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
    ld bc, hPlayerRemX
    ld d, 0
    MV8 e, [bc]
    add hl, de
    MV8 [bc], l

    ld a, h
    cp a, d
    call nz, move_x
    ret


section "Physics HRAM", hram
hPlayerRemX: db
