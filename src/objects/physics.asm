include "../hardware.inc"
include "../attrs.inc"

section "Physics ROM", rom0


;; Resets the physics variables
PhysicsLoad::
    ld hl, hPlayerRemX
    ld de, hEnd - hPlayerRemX
    jp MemoryClear


;; Updates a value until it meets a target
;; This is called `appr` in the original source code, likely short for
;; appreciate.
;;
;; @param hl: Current value
;; @param bc: Target value
;; @param de: Rate to increase or decrease by
;; @returns hl: New value
PhysicsAccelerate::
    ; Subtract the target value from HL so we can easily check if it is larger
    ; or smaller (signed) by checking the sign bit
    ld a, l
    sub a, c
    ld l, a
    ld a, h
    sbc a, b
    ld h, a
    ; Check if we are smaller than the target value
    bit 7, h
    jr z, .deccelerate

    ; If the current value is less than the target value we add to it
    add hl, de
    ; Check if we have gone too far
    bit 7, h
    jr nz, .return
    jr .equal

.deccelerate:
    ; If the current value is greater than the target we subtract from it
    ld a, l
    sub a, e
    ld l, a
    ld a, h
    sbc a, d
    ld h, a
    ; Check if we have gone too far
    bit 7, h
    jr z, .return

.equal:
    ; If we are on one side of the target but adding/subtracting put us on the
    ; other side, then we must set them equal. We do this by setting HL to 0
    ; so the addition below sets it to BC.
    ld hl, 0
.return:
    ; Undo the offset done by the target value
    add hl, bc
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


;; @param h: X movement amount
moveX:
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
    bit ATTRB_SOLID, a
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
    bit ATTRB_SOLID, a
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


;; @param h: Y movement amount
moveY:
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
    bit ATTRB_SOLID, a
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
    bit ATTRB_SOLID, a
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


;; Moves the player using the physics engine. Despite every object having
;; physics in Celeste the player is the only one that uses it.
PhysicsMovePlayer::
    ld hl, wPlayerSpeedX
    ; -- [x] get move amount --
    ; Read the speed X
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    ; Save HL for later when reading the speed Y
    push hl
    ; We add the remainder to the speed, and use the high byte to move the
    ; player. The low byte gets saved back as a remainder.
    ldh a, [hPlayerRemX]
    ld l, a
    ld h, 0
    add hl, bc
    ld a, l
    ldh [hPlayerRemX], a
    ; If the movement amount is non-zero, move in the X direction
    ld a, h
    or a, a
    call nz, moveX

    ; -- [y] get move amount --
    ; Read the speed Y
    pop hl
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    ; Figure out the movement amount and new remainder
    ldh a, [hPlayerRemY]
    ld h, 0
    ld l, a
    add hl, bc
    ld a, l
    ldh [hPlayerRemY], a
    ; If the movement is non-zero, move in the Y direction
    ld a, h
    or a, a
    jp nz, moveY
    ret


section "Physics HRAM", hram
hPlayerRemX: db
hPlayerRemY: db
hEnd:
