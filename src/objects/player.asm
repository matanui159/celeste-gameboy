include "../hardware.inc"
include "../attrs.inc"

section "Player ROM", rom0


;; @param l: Tile position
PlayerLoad::
    push hl
    ; Clear out the tile the player is at
    xor a, a
    call MapTileUpdate
    ; Restore HL since the update overwrites it
    pop hl
    push hl
    call MapTilePosition
    ld hl, wObjectPlayer
    ; Y
    ld a, c
    ld [hl+], a
    ; X
    ld a, b
    ld [hl+], a
    ; Tile ID
    ld a, 1
    ld [hl+], a
    ; Attributes, DMG OBP1, CGB we set the palette during first update
    ld [hl], OAMF_PAL1

    ; Reset player and physics variables
    ld hl, wStart
    ld de, wEnd - wStart
    call MemoryClear
    ; Clear the HRAM variables
    ld hl, hStart
    ld de, hEnd - hStart
    call MemoryClear

    ; Set the inital dash count
    ; TODO: make this modifiable using a "max dash" variable
    ld a, 1
    ldh [hDashCount], a
    pop hl
    ret


;; Performs the calculations to start a dash. We put this in its own function 
;; due to the size and complexity of it.
StartDash:
    ; Figure out the initial X speed for the dash using the left and right
    ; buttons
    ldh a, [hInput]
    bit PADB_RIGHT, a
    jr z, .rightEnd
    ld bc, 5.0 >> 8
    jr .endX
.rightEnd:
    bit PADB_LEFT, a
    jr z, .leftEnd
    ld bc, -(5.0 >> 8)
    jr .endX
.leftEnd:
    ld bc, 0.0 >> 8
.endX:

    ; Figure out the initial Y speed for the dash using the up and down buttons
    bit PADB_UP, a
    jr z, .upEnd
    ld de, -(5.0 >> 8)
    jr .endY
.upEnd:
    bit PADB_DOWN, a
    jr z, .downEnd
    ld de, 5.0 >> 8
    jr .endY
.downEnd:
    ld de, 0.0 >> 8
.endY:

    ; If both X and Y are zero, update based on the players flip state
    ; At this point X and Y speeds are always greater than 1 so we only have to
    ; check the high byte
    ld a, b
    or a, a
    jr nz, .flipEnd
    ld a, d
    or a, a
    jr nz, .flipEnd
    ; Check the flip state of the player
    ld a, [wObjectPlayer + OAMA_FLAGS]
    bit OAMB_XFLIP, a
    ; Set the player as facing right, overwrite if wrong
    ld bc, 1.0 >> 8
    jr z, .flipEnd
    ; Player is facing left
    ld bc, -(1.0 >> 8)
.flipEnd:

    ; If both X and Y are non-zero, reduce the speed down so the diagonal speed
    ; still equals 1
    ld a, b
    or a, a
    jr z, .diagEndY
    ld a, d
    or a, a
    jr z, .diagEndY
    ; The only possible values here is 5 and -5. We can't have the speed 1 or -1
    ; since that only happens on one axis. Thus, we just check if its negative
    ; and set it to 3.54 or -3.54 respectively.
    bit 7, b
    ld bc, 3.535533906 >> 8
    jr z, .diagEndX
    ; X speed is negative
    ld bc, -(3.535533906 >> 8)
.diagEndX:
    ; Same for the Y axis
    bit 7, d
    ld de, 3.535533906 >> 8
    jr z, .diagEndY
    ; Y speed is negative
    ld de, -(3.535533906 >> 8)
.diagEndY:

    ; Save speed X and Y
    ld hl, wPlayerSpeedX
    ; Speed X
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ; Speed Y
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a

    ; Calculate the dash target, which is 2*sign(speed), so we check the sign
    ; bit and check if it is zero or not
    ; Target X
    ; For checking zero, all the possible values so far are >=1.0 so we only
    ; need to check the high byte
    ld a, b
    or a, a
    ; If the speed is 0, the target is 0, so we don't have to make any changes
    jr z, .targetEndX
    ; Otherwise we set it to either 2 or -2 depending on the sign
    bit 7, b
    ld bc, 2.0 >> 8
    jr z, .targetEndX
    ; If the speed is negative, the target is -2
    ld bc, -(2.0 >> 8)
.targetEndX:
    ; Target Y
    ; Check for zero
    ld a, d
    or a, a
    jr z, .targetEndY
    ; Otherwise set based on sign
    bit 7, d
    ld de, 2.0 >> 8
    jr z, .targetEndY
    ; As a special case for the Y axis, the max speed up is 1.5
    ld de, -(1.5 >> 8)
.targetEndY:

    ; Write the target speed X and Y
    ; Target X
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ; Target Y
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a

    ; Finally we must calculate teh acceleration. This will be the same for both
    ; values and becomes ~1.06 when dashing diagonally and 1.5 otherwise
    ; Like before, the only values that are possible in the target X and Y
    ; registers are all >=1.0 so we only have to check the highest byte for
    ; non-zero
    ld a, b
    or a, a
    ; We modify BC now since we have the flag so we don't need it anymore
    ; Like similar code above, we assume one case and update it if wrong
    ld bc, 1.5 >> 8
    jr z, .accelDiagEnd
    ld a, d
    or a, a
    jr z, .accelDiagEnd
    ; We are moving diagonally
    ld bc, 1.060660172 >> 8
.accelDiagEnd:

    ; Write the acceleration to both X and Y
    ; TODO: anyway to optimize this such that we don't have to swap A back and
    ;       forth?
rept 2
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
endr
    ret


;; Accelerates a single axis using the speed, target and acceleration in memory
;; @param hl: Pointer to the speed parameter to start reading from
;; @effects hl: Pointer to the next speed parameter
DashAccelerate:
    ; Save HL for later
    push hl
    ; Speed
    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    ; Target
    inc hl
    inc hl
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    ; Acceleration
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ; Swap HL and DE and accelerate
    ld a, h
    ld h, d
    ld d, a
    ld a, l
    ld l, e
    ld e, a
    call PhysicsAccelerate
    ; Save the speed back using the saved pointer above
    ld a, l
    ld b, h
    pop hl
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ret


;; Update the player object
PlayerUpdate::
    ; Update the jump buffer
    ldh a, [hInputNext]
    bit PADB_A, a
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

    ; Update the grace period
    ; Check if we are on solid ground
    ldh a, [hPlayerGroundFlags]
    bit ATTRB_SOLID, a
    jr nz, .onGround
    ; If the player is not on the ground, decrement grace period
    ldh a, [hGrace]
    or a, a
    jr z, .graceEnd
    dec a
    jr .graceEnd
.onGround:
    ; If the player is on the ground reset the dash count
    ld a, 1
    ldh [hDashCount], a
    ; Reset the grace period
    ld a, 6
.graceEnd:
    ldh [hGrace], a

    ; If we are in a dash, apply the acceleration for 4 frames
    ldh a, [hDashTime]
    or a, a
    jr z, .dashAccelEnd
    ; Decrement the dash timer
    dec a
    ldh [hDashTime], a
    ; Accelerate the X speed
    ld hl, wPlayerSpeedX
    call DashAccelerate
    ; Accelerate the Y speed (the above function call increments HL)
    call DashAccelerate
    ; Spawn a smoke particle
    ld hl, wObjectPlayer
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    call SmokeSpawn
    ; Skip everything else, using a jump because it is too far
    jp .animate
.dashAccelEnd:

    ; -- move --
    ; Read the current speed X
    ld hl, wPlayerSpeedX
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ; If the player is on the ground the acceleration is 0.6
    ld de, 0.6 >> 8
    ; Check if the player is in the air
    ldh a, [hPlayerGroundFlags]
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
    bit PADB_RIGHT, a
    jr z, .moveRightEnd
    ld bc, 1.0 >> 8
    jr .moveAccel
.moveRightEnd:
    ; Accelerate left if the button is pressed
    bit PADB_LEFT, a
    jr z, .moveLeftEnd
    ld bc, -(1.0 >> 8)
    jr .moveAccel
.moveLeftEnd:
    ; Otherwise deccelerate towards zero
    ld bc, 0.0 >> 8

.moveAccel:
    call PhysicsAccelerate
    ; Write the new speed X
    ld a, l
    ld b, h
    ld hl, wPlayerSpeedX
    ld [hl+], a
    ld [hl], b

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

    ; -- dash --
    ; Check if the player has pressed the dash button
    ldh a, [hInputNext]
    bit PADB_B, a
    jr z, .dashEnd
    ; Check if the player has any dashes left
    ldh a, [hDashCount]
    or a, a
    jr z, .dashEnd
    ; Update the dash count and dash timer
    dec a
    ldh [hDashCount], a
    ld a, 4
    ldh [hDashTime], a
    ; Call the dash subroutine
    call StartDash
.dashEnd:

.animate:
    ; -- animation --
    ; Increment the sprite offset, calculate the expected sprite in B
    ldh a, [hSpriteOffset]
    inc a
    ldh [hSpriteOffset], a
    rra
    rra
    and a, $03
    inc a
    ld b, a

    ; We calculate the new attributes into C using the palette and X facing
    ; while also setting the DMG palette into D
    ; Set the hair color
    ld hl, wObjectPlayer + OAMA_FLAGS
    ld a, [hl]
    and a, ~OAMF_PALMASK
    ld c, a
    ldh a, [hDashCount]
    ; We can compare against one so we can check less-than (0), equal (1),
    ; or neither (2)
    cp a, 1
    ; If the hair is blue, palette 0, we don't have to OR anything
    ; For DMG we do have to set D, but lets just set that here :)
    ld d, %10_01_10_11
    jr c, .hairEnd
    ; Hair is red, palette 1. On DMG we set the highest color to white.
    ld d, %00_01_10_11
    set 0, c
.hairEnd:
    ; Save the DMG palette
    ld a, d
    ldh [hDMGPalette], a

    ; -- facing --
    ; We update facing now as part of animation, so that we can also detect if
    ; the player is moving. Note that we don't use the player speed to detect
    ; the facing and just use the buttons.
    ldh a, [hInput]
    bit PADB_RIGHT, a
    jr z, .facingRightEnd
    ; Facing right, don't flip
    res OAMB_XFLIP, c
    jr .facingEnd
.facingRightEnd:
    bit PADB_LEFT, a
    jr z, .facingLeftEnd
    ; Facing left, flip the sprite
    set OAMB_XFLIP, c
    jr .facingEnd
.facingLeftEnd:
    ; Neither facing left or right, don't update the flags but set the sprite as
    ; stationary
    ld b, 1
.facingEnd:
    ; Update the attributes and decrement HL for updating the sprite later
    ld a, c
    ld [hl-], a

    ; If we are not on the ground, set the sprite to 3
    ldh a, [hPlayerGroundFlags]
    bit ATTRB_SOLID, a
    jr nz, .animateGround
    ld b, 3
    jr .animateEnd
.animateGround:
    ; If the player is looking down, set the sprite to 6
    ldh a, [hInput]
    bit PADB_DOWN, a
    jr z, .animateDownEnd
    ld b, 6
    jr .animateEnd
.animateDownEnd:
    ; If the player is looking up, set the sprite to 7
    bit PADB_UP, a
    ; Otherwise we just skip to the end using the existing sprite using the
    ; movement state
    jr z, .animateEnd
    ld b, 7
.animateEnd:
    ; Update the sprite
    ld [hl], b

    ; Get the physics engine to move the player using the speed
    jp PhysicsMovePlayer


section fragment "VBlank", rom0
VBlankPlayer:
    ; Check if we are on DMG
    ldh a, [hMainBoot]
    cp a, BOOTUP_A_CGB
    jr z, .end
    ; Update the DMG palette
    ldh a, [hDMGPalette]
    ldh [rOBP1], a
.end:


section "Player WRAM", wram0
wStart:
wPlayerSpeedX:: dw
wPlayerSpeedY:: dw
wDashTargetX: dw
wDashTargetY: dw
wDashAccelX: dw
wDashAccelY: dw
wEnd:

section "Player HRAM", hram
hStart:
hPlayerRemX:: db
hPlayerRemY:: db
hPlayerGroundFlags:: db
hJumpBuffer: db
hGrace: db
hDashCount: db
hDashTime: db
hSpriteOffset: db
hDMGPalette: db
hEnd:
