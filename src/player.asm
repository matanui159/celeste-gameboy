include "hardware.inc"
include "input.inc"
include "attrs.inc"

section "Player ROM", rom0


;; @param l: Tile position
PlayerLoad::
    call MapTilePosition
    push hl
    ld hl, wObjectPlayer
    ; Y
    ld [hl], c
    inc l
    ; X
    ld [hl], b
    inc l
    ; Tile ID
    ld [hl], 1
    inc l
    ; Attributes, palette index 0
    ld [hl], 0

    ; Reset player and physics variables
    xor a, a
    ld hl, wPlayerSpeedX
    ; Speed X
    ld [hl+], a
    ld [hl+], a
    ; Speed Y
    ld [hl+], a
    ld [hl+], a
    ldh [hGroundFlags], a
    ldh [hGroundFlagsNext], a
    ldh [hJumpBuffer], a
    ldh [hGrace], a
    call PhysicsLoad
    pop hl
    ret


;; Update the player object
PlayerUpdate::
    ; Update the jump buffer
    ldh a, [hInputNext]
    bit INB_A, a
    ld a, 4
    jr nz, .jumpBufferEnd
    ; If the jump button wasn't pressed, decrement the jump-buffer unless it is
    ; already zero
    ldh a, [hJumpBuffer]
    or a, a
    jr z, .jumpBufferEnd
    dec a
.jumpBufferEnd:
    ldh [hJumpBuffer], a

    ; Update the ground flags
    ; Get the player position...
    ld hl, wObjectPlayer
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    ; ... to find if there is solid below
    inc c
    call PhyscisPlayerTileFlags
    ; Save into HRAM and compare against the previous frame
    ld d, a
    ldh a, [hGroundFlags]
    cpl
    and a, d
    ; We also save this in a register so we can quickly check it later
    ld e, a
    ldh [hGroundFlagsNext], a
    ld a, d
    ldh [hGroundFlags], a

    ; Update the grace period
    ; Check if we are on solid ground
    bit ATTRB_SOLID, a
    ld a, 6
    jr nz, .graceEnd
    ; If the player is not on the ground, decrement grace period
    ldh a, [hGrace]
    or a, a
    jr z, .graceEnd
    dec a
.graceEnd:
    ldh [hGrace], a

    ; Check if we have just landed
    bit ATTRB_SOLID, e
    jr z, .landEnd
    ; If we have just landed, spawn a smoke particle at offset 0,+4
    ; We already have the player positon in BC with an offset of 0,+1 from above
    ld a, c
    add a, 3
    ld c, a
    call SmokeSpawn
.landEnd:

    ; -- move --
    ; Read the current speed X
    ld hl, wPlayerSpeedX
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ; If the player is on the ground the acceleration is 0.6
    ld de, 0.6 >> 8
    ; Check if the player is in the air
    ldh a, [hGroundFlags]
    bit ATTRB_SOLID, a
    jr nz, .moveAirEnd
    ; If the player is in the air, the acceleration is 0.4
    ld de, 0.4 >> 8
.moveAirEnd:

    ; Deccelerate if the current absolute speed is larger than 1
    bit 7, h
    jr nz, .moveDeccelNeg
    ; If the speed is positive the high-byte must be non-zero
    ld a, h
    cp a, 1
    jr c, .moveDeccelEnd
    ; Edge case: when it is exactly equal to 1.0 we should skip this
    jr nz, .moveDeccelNot1
    ld a, l
    or a, a
    jr z, .moveDeccelEnd
.moveDeccelNot1:
    ; If it is we decrement to 1.0
    ld bc, 1.0 >> 8
    ld de, 0.15 >> 8
    jr .moveAccel
.moveDeccelNeg:
    ; If the speed is negative the high byte must be anything but $ff
    ld a, h
    inc a
    jr z, .moveDeccelEnd
    ; If it is we increment to -1.0
    ld bc, -(1.0 >> 8)
    ld de, 0.15 >> 8
    jr .moveAccel
.moveDeccelEnd:

    ; Accelerate right if the button is pressed
    ldh a, [hInput]
    bit INB_RIGHT, a
    jr z, .moveRightEnd
    ld bc, 1.0 >> 8
    jr .moveAccel
.moveRightEnd:
    ; Accelerate left if the button is pressed
    bit INB_LEFT, a
    jr z, .moveLeftEnd
    ld bc, -(1.0 >> 8)
    jr .moveAccel
.moveLeftEnd:
    ; Otherwise deccelerate towards zero
    ld bc, 0.0 >> 8

.moveAccel:
    call PhysicsAccelerate

    ; -- facing --
    ; We handle this now while we still have the speed in the registers
    ; We skip this and keep the old facing value if the speed is 0
    ld a, h
    or a, a
    jr nz, .updateFacing
    ld a, l
    or a, a
    jr z, .facingEnd
.updateFacing:
    ; Clear the old flip flag
    ld a, [wObjectPlayer + OAMA_FLAGS]
    and a, ~OAMF_XFLIP
    ; Set the flip flag if the speed is negative
    bit 7, h
    jr z, .facingRight
    set OAMB_XFLIP, a
.facingRight:
    ld [wObjectPlayer + OAMA_FLAGS], a
.facingEnd:

    ; Finish updating movement from above
    ; Write the new speed X
    ld a, l
    ld b, h
    ld hl, wPlayerSpeedX
    ld [hl+], a
    ld [hl], b
    ; Get the physics engine to move the player left and right
    ld c, a
    call PhysicsMovePlayerX

    ; -- gravity --
    ; Read speed Y
    ld hl, wPlayerSpeedY
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ; Set the max falling speed to 2.0 and gravity to 0.21
    ld bc, 2.0 >> 8
    ld de, 0.21 >> 8

    ; Gravity is weaker if the absolute speed is <= 0.15
    bit 7, h
    jr nz, .gravLowNeg
    ; The high byte must be 0
    ld a, h
    or a, a
    jr nz, .gravityAccel
    ; The low byte must be <0.15
    ld a, l
    cp a, 0.15 >> 8
    jr nc, .gravityAccel
    jr .gravLowAccel
.gravLowNeg:
    ; The high byte must be $ff
    ld a, h
    inc a
    jr nz, .gravityAccel
    ; The low byte must be > -0.15
    cp a, -(0.15 >> 8)
    jr c, .gravityAccel
.gravLowAccel:
    ; We divide the gravity by 2
    srl d
    rr e

.gravityAccel:
    call PhysicsAccelerate

    ; -- jump --
    ; Both the jump-buffer and the grace period have to be non-zero
    ldh a, [hJumpBuffer]
    or a, a
    jr z, .jumpEnd
    ldh a, [hGrace]
    or a, a
    jr z, .jumpEnd
    ; -- normal jump --
    ; Clear both variables
    xor a, a
    ldh [hJumpBuffer], a
    ldh [hGrace], a
    ; Spawn a smoke particle at offset 0,4
    ld hl, wObjectPlayer
    ld a, [hl+]
    add a, 4
    ld c, a
    ld b, [hl]
    call SmokeSpawn
    ; Set the vertical speed to -2
    ld hl, -(2.0 >> 8)
.jumpEnd:

    ; Write new speed Y
    ld a, l
    ld b, h
    ld hl, wPlayerSpeedY
    ld [hl+], a
    ld [hl], b
    ; Get the physics engine to move up and down
    ld c, a
    call PhysicsMovePlayerY
    ret


section "Player WRAM", wram0
wPlayerSpeedX:: dw
wPlayerSpeedY:: dw

section "Player HRAM", hram
hGroundFlags: db
hGroundFlagsNext: db
hJumpBuffer: db
hGrace: db
