include "hardware.inc"

section "Physics ROM", rom0


; Resets the physics variables
PhysicsLoad::
    xor a, a
    ldh [hPlayerRemX], a
    ldh [hPlayerRemY], a
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


;; ORs all the flags of all the tiles the player collides with
;; @param bc: Player position
;; @returns a: Tile flags
;; @saved bc
PhyscisPlayerTileFlags::
    ; First we check the top-left tile, near the X/Y position
    ; The player has a hitbox offset of 1, 3
    inc b
    inc c
    inc c
    inc c
    ; These are in seperate calls since we only need to find the tile once
    ; and then can get the attributes from offsets of that tile
    call MapFindTileAt
    call MapTileAttributes
    ; Save the attributes for now
    push af

    ; Check the top-right tile (1 to the right)
    ; The hitbox width is 6 so we only need to check this if X % 8 >= 3
    ld a, b
    and a, $07
    cp a, 3
    jr c, .skipRight
    ; Check 1 tile to the right
    inc l
    call MapTileAttributes
    ; OR it with the previous attributes currently in the stack
    pop de
    or a, d
    push af

.skipRight:
    ; Check the bottom-right tile (1 down)
    ; The hitbox height is 5 so we only need to check this if Y % 8 >= 4
    ld a, c
    and a, $07
    cp a, 4
    jr c, .return
    ; Check 1 tile down
    ld a, l
    add a, $10
    ld l, a
    call MapTileAttributes
    ; OR with previous attributes
    pop de
    or a, d
    push af

    ; Check the bottom-left tile (1 to the left)
    ; We have to check left/right differences again because we may jump here
    ; from the top-right check
    ld a, b
    and a, $07
    cp a, 3
    jr c, .return
    dec l
    call MapTileAttributes
    ; OR with previous attributes
    pop de
    or a, d
    ; We push here still due to sometimes things skipping over to the return code
    push af

.return:
    ; Undo the hitbox offset
    dec b
    dec c
    dec c
    dec c
    pop af
    ret


;; @param bc: Speed X
PhysicsMovePlayerX::
    ; -- [x] get move amount --
    ; We add the remainder to the speed, and use the high byte to move the
    ; player. The low byte gets saved back as a remainder.
    ldh a, [hPlayerRemX]
    ld l, a
    ld h, 0
    add hl, bc
    ld a, l
    ldh [hPlayerRemX], a
    ; If the movement amount is zero we don't move at all
    ld a, h
    or a, a
    ret z

    ; Get the position
    ld a, [wObjectPlayer + OAMA_X]
    ld b, a
    ld a, [wObjectPlayer + OAMA_Y]
    ld c, a
    ; Check in which direction we are moving
    bit 7, h
    jr nz, .moveLeft

    ; There seems to be a bug in the original source code that makes it do one
    ; more step than it needs to. We replicate that bug here
    inc h
.rightLoop:
    ; Moving right (positive)
    inc b
    push hl
    call PhyscisPlayerTileFlags
    pop hl
    ; Check the solid attribute
    bit 3, a
    jr nz, .solidRight
    ; If it is not solid, keep moving
    dec h
    jr nz, .rightLoop
    jr .return
.solidRight:
    ; If it is solid, go back
    dec b
    jr .solid

.moveLeft:
    ; Replicate bug
    dec h
.leftLoop:
    ; Moving left (negative)
    dec b
    push hl
    call PhyscisPlayerTileFlags
    pop hl
    ; Check the solid attribute
    bit 3, a
    jr nz, .solidLeft
    ; Keep moving
    inc h
    jr nz, .leftLoop
    jr .return
.solidLeft:
    ; Go back
    inc b

.solid:
    ; Shared collision code between left/right movement
    ; If we have hit something we want to round to that pixel and reset the
    ; speed
    xor a, a
    ldh [hPlayerRemX], a
    ld hl, wPlayerSpeedX
    ld [hl+], a
    ld [hl+], a
.return:
    ; Save the new X position and return
    ld a, b
    ld [wObjectPlayer + OAMA_X], a
    ret


;; @param bc: Speed Y
PhysicsMovePlayerY::
    ; -- [y] get move amount --
    ; Figure out the movement amount and new remainder
    ldh a, [hPlayerRemY]
    ld h, 0
    ld l, a
    add hl, bc
    ld a, l
    ldh [hPlayerRemY], a
    ; If the movement is zero, don't move at all
    ld a, h
    or a, a
    ret z

    ; Get the position
    ld a, [wObjectPlayer + OAMA_X]
    ld b, a
    ld a, [wObjectPlayer + OAMA_Y]
    ld c, a
    ; Check which direction we're moving
    bit 7, h
    jr nz, .moveUp

    ; Replicate bug
    inc h
.downLoop:
    ; Moving down (positive)
    inc c
    push hl
    call PhyscisPlayerTileFlags
    pop hl
    ; Check if solid
    bit 3, a
    jr nz, .solidDown
    ; Keep moving
    dec h
    jr nz, .downLoop
    jr .return
.solidDown:
    ; Go back
    dec c
    jr .solid

.moveUp:
    ; Replicate bug
    dec h
.upLoop:
    ; Moving up (negative)
    dec c
    push hl
    call PhyscisPlayerTileFlags
    pop hl
    ; Check if solid
    bit 3, a
    jr nz, .solidUp
    ; Keep moving
    inc h
    jr nz, .upLoop
    jr .return
.solidUp:
    ; Go back
    inc c

.solid:
    ; Shared collision code between up/down
    xor a, a
    ldh [hPlayerRemY], a
    ld hl, wPlayerSpeedY
    ld [hl+], a
    ld [hl+], a
.return:
    ; Save the new Y position
    ld a, c
    ld [wObjectPlayer + OAMA_Y], a
    ret


section "Physics HRAM", hram
hPlayerRemX: db
hPlayerRemY: db
