include "hardware.inc"
include "input.inc"

section "Player ROM", rom0


;; @param l: Tile position
PlayerLoad::
    call MapTilePosition
    push hl
    ld hl, wObjectPlayer
    ; X
    ld [hl], c
    inc l
    ; Y
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
    call PhysicsLoad
    pop hl
    ret


;; Update the player object
PlayerUpdate::
    ; -- move --
    ; Read the current speed X
    ld hl, wPlayerSpeedX
    ld a, [hl+]
    ld h, [hl]
    ld l, a

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
    ld de, -(0.15 >> 8)
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
    ld de, 0.6 >> 8
    jr .moveAccel
.moveRightEnd:
    ; Accelerate left if the button is pressed
    bit INB_LEFT, a
    jr z, .moveLeftEnd
    ld bc, -(1.0 >> 8)
    ld de, -(0.6 >> 8)
    jr .moveAccel
.moveLeftEnd:

    ; Deccelerate towards zero
    bit 7, h
    ld bc, 0
    jr nz, .moveZeroNeg
    ld de, -(0.6 >> 8)
    jr .moveAccel
.moveZeroNeg:
    ld de, 0.6 >> 8

.moveAccel:
    call PhysicsAccelerate
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
    ; Set the max falling speed to 2.0
    ld bc, 2.0 >> 8

    ; Gravity is weaker if the absolute speed is <= 0.15
    bit 7, h
    jr nz, .gravLowNeg
    ; The high byte must be 0
    ld a, h
    or a, a
    jr nz, .gravLowEnd
    ; The low byte must be <0.15
    ld a, l
    cp a, 0.15 >> 8
    jr nc, .gravLowEnd
    jr .gravLowAccel
.gravLowNeg:
    ; The high byte must be $ff
    ld a, h
    inc a
    jr nz, .gravLowEnd
    ; The low byte must be > -0.15
    cp a, -(0.15 >> 8)
    jr c, .gravLowEnd
.gravLowAccel:
    ; Set the gravity to 0.21 / 2
    ld de, (0.21 / 2) >> 8
    ; We don't have to check if the current speed is larger than the max speed
    ; since we already know at most its 0.15
    jr .gravityAccel
.gravLowEnd:

    ; If the Y speed is too high we have to deccelerate to the max fall speed
    ; We do this because the `PhysicsAccelerate` function does not do it for
    ; us (it made the code too complicated and is not needed most of the time).
    ; We do a 16-bit compare by inverting the top bits so positive values are
    ; larger than negative ones
    ld a, h
    xor a, $80
    ld d, a
    ld a, b
    xor a, $80
    ld e, a
    ld a, l
    sub a, c
    ld a, d
    sub a, e
    jr c, .gravDeccelEnd
    ; Use a negative gravity
    ld de, -(0.21 >> 8)
    jr .gravityAccel
.gravDeccelEnd:

    ; Otherwise we just do normal gravity acceleration
    ld de, 0.21 >> 8

.gravityAccel:
    call PhysicsAccelerate
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
