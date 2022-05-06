include "../hardware.inc"
include "../attrs.inc"

section "Physics ROM", rom0


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


;; Handles collision for all the tiles the player is colliding with, and ORs all
;; the flags of all those tiles
;; @param bc: Player position
;; @returns a: Tile flags
;; @saved bc
CollideTilesAtPlayer:
    ; First we check the top-left corner, near the X/Y position
    ; The player has a hitbox offset of 1, 3
    inc b
    inc c
    inc c
    inc c
    call MapCollideTileAt
    ; Save the attributes for now
    push af

    ; Check the top-right corner, the hitbox width is 6
    ; We add one pixel less so we get the last pixel not the next pixel
    ld a, b
    add a, 5
    ld b, a
    call MapCollideTileAt
    ; OR it with the previous attributes currently in the stack
    pop de
    or a, d
    push af

    ; Check the bottom-right tile, the hitbox height is 5
    ld a, c
    add a, 4
    ld c, a
    call MapCollideTileAt
    ; OR with previous attributes
    pop de
    or a, d
    push af

    ; Check the bottom-left tile
    ld a, b
    sub a, 5
    ld b, a
    call MapCollideTileAt
    ; OR with previous attributes
    pop de
    or a, d
    ; Save into D for now
    ld d, a

    ; Restore the original position
    dec b
    ld a, c
    sub a, 7
    ld c, a
    ld a, d
    ret


;; Updates the ground flags and spawns a smoke particle if needed
;; @param bc: Player position
;; @param  a: Ground flags
;; @saved bc
;; @saved  a
UpdateGroundFlags::
    ld hl, hPlayerGroundFlags
    ld d, [hl]
    ld [hl], a
    ; Check if we were not on the ground the previous frame
    bit ATTRB_SOLID, d
    ret nz    
    ; Check if we are currently on the ground
    bit ATTRB_SOLID, a
    ret z
    ; The player has just landed, spawn a smoke particle
    push af
    push bc
    ; The smoke particle has an offset of 0,+4
    ld a, c
    add a, 4
    ld c, a
    call SmokeSpawn
    pop bc
    pop af
    ret


;; @param h: X movement amount
MovePlayerX:
    ; Note that unlike the orignal Celeste code, this port does movement as a
    ; single step. If that single step collides with something, we align the
    ; player to the closest tile.
    ; TODO: as further optimization, maybe we should only check either the left
    ;       two or the right two corners.

    ; Get the position
    ld a, [wObjectPlayer + OAMA_X]
    add a, h
    ld b, a
    ld a, [wObjectPlayer + OAMA_Y]
    ld c, a
    ; Check in which direction we are moving
    bit 7, h
    jr nz, .moveLeft

    ; Moving right (positive)
    ; There seems to be a bug in the original source code that makes it do one
    ; more step than it needs to. We replicate that bug here
    inc b
    call CollideTilesAtPlayer
    ; Check the solid attribute
    bit ATTRB_SOLID, a
    jr z, .return
    ; If it is solid, align the right edge of the player hitbox with the left
    ; edge of the tile.
    ld a, b
    add a, 7
    and a, $f8
    sub a, 7
    ld b, a
    jr .solid

.moveLeft:
    ; Moving left (negative)
    ; Replicate bug
    dec b
    call CollideTilesAtPlayer
    ; Check the solid attribute
    bit ATTRB_SOLID, a
    jr z, .return
    ; Align left side
    ld a, b
    inc a
    and a, $f8
    ; Add 8 (right side of tile), minus 1 (hitbox offset)
    add a, 7
    ld b, a

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
MovePlayerY:
    ; Get the position
    ld a, [wObjectPlayer + OAMA_X]
    ld b, a
    ld a, [wObjectPlayer + OAMA_Y]
    add a, h
    ld c, a

    ; Check which direction we're moving
    bit 7, h
    jr nz, .moveUp

    ; Moving down (positive)
    ; Replicate bug
    inc c
    call CollideTilesAtPlayer
    ; Update the ground flags
    call UpdateGroundFlags
    ; Check if solid
    bit ATTRB_SOLID, a
    jr z, .return
    ; Align bottom side
    ld a, c
    add a, 8
    and a, $f8
    sub a, 8
    ld c, a
    jr .solid

.moveUp:
    ; Moving up (negative)
    ; If we are moving upwards, we reset the ground flags
    xor a, a
    ldh [hPlayerGroundFlags], a
    ; Replicate bug
    dec c
    call CollideTilesAtPlayer
    ; Check if solid
    bit ATTRB_SOLID, a
    jr z, .return
    ; Align top side
    ld a, c
    add a, 3
    and a, $f8
    ; Add 8, minus 3
    add a, 5
    ld c, a

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
    ; -- [x] get move amount --
    ; Read the speed X
    ld hl, wPlayerSpeedX
    ld a, [hl+]
    ld c, a
    ld b, [hl]
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
    call nz, MovePlayerX

    ; -- [y] get move amount --
    ; Read the speed Y
    ld hl, wPlayerSpeedY
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
    ; This call will return after it is finished
    jp nz, MovePlayerY
    ; If the speed is zero, we still do a check to update the ground flags
    ld hl, wObjectPlayer
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    inc c
    call CollideTilesAtPlayer
    dec c
    jp UpdateGroundFlags
