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
    jr nz, .deccelNegSpeed
    ; If the speed is positive the high-byte must be non-zero
    ld a, h
    cp a, 1
    jr c, .deccelEnd
    ; Edge case: when it is exactly equal to 1.0 we should skip this
    jr nz, .deccelNot1
    ld a, l
    or a, a
    jr z, .deccelEnd
.deccelNot1:
    ; If it is we decrement to 1.0
    ld bc, 1.0 >> 8
    ld de, -(0.15 >> 8)
    jr .moveAccel
.deccelNegSpeed:
    ; If the speed is negative the high byte must be anything but $ff
    ld a, h
    inc a
    jr z, .deccelEnd
    ; If it is we increment to -1.0
    ld bc, -(1.0 >> 8)
    ld de, 0.15 >> 8
    jr .moveAccel
.deccelEnd:

    ; Accelerate right if the button is pressed
    ldh a, [hInput]
    bit INB_RIGHT, a
    jr z, .rightEnd
    ld bc, 1.0 >> 8
    ld de, 0.6 >> 8
    jr .moveAccel
.rightEnd:
    ; Accelerate left if the button is pressed
    bit INB_LEFT, a
    jr z, .leftEnd
    ld bc, -(1.0 >> 8)
    ld de, -(0.6 >> 8)
    jr .moveAccel
.leftEnd:

    ; Deccelerate towards zero
    bit 7, h
    ld bc, 0
    jr nz, .zeroNeg
    ld de, -(0.6 >> 8)
    jr .moveAccel
.zeroNeg:
    ld de, 0.6 >> 8

.moveAccel:
    call PhysicsAccelerate
    ; Write the new speed X
    ld a, l
    ld b, h
    ld hl, wPlayerSpeedX
    ld [hl+], a
    ld [hl], b

    ; Get the physics engine to move the player
    ld c, a
    call PhysicsMovePlayer
    ret


section "player_wram", wram0
wPlayerSpeedX:: dw
