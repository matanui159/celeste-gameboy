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


;; Finds all the tiles the player is colliding with, and calls the specified
;; callback for each one.
;; @param bc: Player position
;; @param hl: Tile callback
;; @saved bc
FindTilesAtPlayer:
    ; First we check the top-left corner, near the X/Y position
    ; The player has a hitbox offset of 1, 3
    inc b
    inc c
    inc c
    inc c
    push hl
    call MapFindTileAt
    pop hl
    ; Call the callback
    rst $30

    ; Check the top-right corner, the hitbox width is 6
    ; We add one pixel less so we get the last pixel not the next pixel
    ld a, b
    add a, 5
    ld b, a
    push hl
    call MapFindTileAt
    pop hl
    ; Call the callback
    rst $30

    ; Check the bottom-right tile, the hitbox height is 5
    ld a, c
    add a, 4
    ld c, a
    push hl
    call MapFindTileAt
    pop hl
    ; Call the callback
    rst $30

    ; Check the bottom-left tile
    ld a, b
    sub a, 5
    ld b, a
    push hl
    call MapFindTileAt
    pop hl
    ; Call the callback
    rst $30

    ; Restore the original position
    dec b
    ld a, c
    sub a, 7
    ld c, a
    ret


;; Gets the flags of a specific tile and ORs it with any existing flags
;; @param a: Tile ID
;; @param d: Existing flags
;; @returns d: Updated Flags
OrTileFlags:
    ld h, high(GenAttrs)
    ld l, a
    ld a, [hl]
    or a, d
    ld d, a
    ; Restore HL since we know if we're here, HL is pointing to this callback
    ld hl, OrTileFlags
    ret


;; Calls collision routines based on the tile ID.
;; @param a: Tile ID
;; @param bc: Collide position
;; @saved hl
;; @saved bc
CollideTile:
    cp a, 17
    jp z, SpikeCollideUp
    cp a, 27
    jp z, SpikeCollideDown
    cp a, 43
    jp z, SpikeCollideRight
    cp a, 59
    jp z, SpikeCollideLeft
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
    ; Setup the tile callback ready
    ld hl, OrTileFlags
    ld d, 0
    jr nz, .moveLeft

    ; Moving right (positive)
    ; There seems to be a bug in the original source code that makes it do one
    ; more step than it needs to. We replicate that bug here
    inc b
    call FindTilesAtPlayer
    ; Check the solid attribute
    bit ATTRB_SOLID, d
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
    call FindTilesAtPlayer
    ; Check the solid attribute
    bit ATTRB_SOLID, d
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
;; @effect bc: New position
MovePlayerY:
    ; Get the position
    ld a, [wObjectPlayer + OAMA_X]
    ld b, a
    ld a, [wObjectPlayer + OAMA_Y]
    add a, h
    ld c, a

    ; Check which direction we're moving
    bit 7, h
    ; Save H into E for now since we might need it later
    ld e, h
    ; Setup the tile callback
    ld hl, OrTileFlags
    ld d, 0
    jr nz, .moveUp

    ; Moving down (positive)
    ; Replicate bug, this is also used to check 1 pixel down if this is called
    ; with a movement amount of 0
    inc c
    call FindTilesAtPlayer
    ; Update the ground flags, saving the old flags in H
    ldh a, [hPlayerGroundFlags]
    ld h, a
    ld a, d
    ldh [hPlayerGroundFlags], a
    ; Check if solid
    bit ATTRB_SOLID, d
    jr z, .noSolid
    ; Align bottom side
    ld a, c
    add a, 8
    and a, $f8
    sub a, 8
    ld c, a
    ; Check if the player has just landed
    bit ATTRB_SOLID, h
    jr nz, .solid
    ; If so, spawn a smoke particle with an offset of 0,+4
    push bc
    add a, 4
    ld c, a
    call SmokeSpawn
    pop bc
    jr .solid

.noSolid:
    ; If no solid surface was found when moving down, check if we should be
    ; moving down (if the original movement amount in E is non-zero) and if not
    ; undo the offset applied and return now.
    dec c
    ld a, e
    or a, a
    ret z
    ; Turns out the player was moving, reapply the increment and return normally
    inc c
    jr .return

.moveUp:
    ; Moving up (negative)
    ; If we are moving upwards, we reset the ground flags
    xor a, a
    ldh [hPlayerGroundFlags], a
    ; Replicate bug
    dec c
    call FindTilesAtPlayer
    ; Check if solid
    bit ATTRB_SOLID, d
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
    ; Always move in the Y direction since the function also handles zero
    ; movement
    call MovePlayerY

    ; Check for collisions, BC is the new position due to effect from MovePlayerY
    ld hl, CollideTile
    jp FindTilesAtPlayer
