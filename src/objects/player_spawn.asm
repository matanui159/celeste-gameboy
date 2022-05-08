include "player.inc"
include "../hardware.inc"

section "Player spawn ROM", rom0


;; @param l: Tile position
PlayerSpawnLoad::
    push hl
    ; Clear out the tile the player is at
    xor a, a
    call MapTileUpdate
    ; Restore HL since the update overwrites it
    pop hl
    push hl
    call MapTilePosition
    ; Save the target Y
    ld a, c
    ldh [hTargetY], a
    ld hl, wObjectPlayer
    ; Y, the player starts below the map
    ldh a, [rSCY]
    ld c, a
    ld a, $80 + OAM_Y_OFS
    sub a, c
    ld [hl+], a
    ; X
    ld a, b
    ld [hl+], a
    ; Tile ID
    ld a, 3
    ld [hl+], a
    ; Attributes, DMG OBP1, CGB we set the palette during first update
    ld [hl], OAMF_PAL1

    ; Set the player type to spawning
    ld a, PLAYER_SPAWN
    ldh [hPlayerType], a
    ; Set initial state to 0 (jumping)
    xor a, a
    ldh [hState], a
    ; Set initial speed to -4
    ld a, -(4.0 >> 15)
    ldh [hSpeedY], a
    pop hl
    ret


;; Updates the player when its in the spawning-animation state
PlayerSpawnUpdate::
    ; Switch between the different spawn states
    ldh a, [hState]
    cp a, 1
    jr z, .falling
    jr nc, .landing

    ; -- jumping up --
    ; Check if we have gotten higher than the target
    ldh a, [hTargetY]
    add a, 16
    ld b, a
    ld a, [wObjectPlayer + OAMA_Y]
    cp a, b
    jr nc, .end
    ; If so, switch to state 1
    ld a, 1
    ldh [hState], a
    ld a, 3
    ldh [hTimer], a
    jr .end

.falling:
    ; -- falling --
    ldh a, [hSpeedY]
    inc a
    ; Check if the speed is now zero or positive
    bit 7, a
    jr nz, .fallingEnd
    ; Delay for 3 frames (set when switched to state 1) before falling
    ld b, a
    ldh a, [hTimer]
    or a, a
    jr z, .fallingDown
    ; We still have delay frames left, decrement and clear speed
    dec a
    ldh [hTimer], a
    xor a, a
    jr .fallingEnd
.fallingDown:
    ; Check if we are now below the target Y
    ldh a, [hTargetY]
    ld c, a
    ld hl, wObjectPlayer + OAMA_Y
    ld a, [hl]
    cp a, c
    ; Restore the speed into A for now so we can safely jump to fallingEnd
    ld a, b
    jr c, .fallingEnd
    ; We have just landed!! Set the Y to the target position
    ; We also increment HL here since we need to read X
    ld a, c
    ld [hl+], a
    ; Calculate a 0,+4 offset for spawning a smoke particle later
    add a, 4
    ld c, a
    ld a, [hl+]
    ld b, a
    ; Change the sprite to 6
    ld [hl], 6
    ; Spawn that smoke particle
    call SmokeSpawn
    ; Switch to state 2
    ld a, 2
    ldh [hState], a
    ; We add one extra to this delay so we can easily DEC and check the Z flag
    ld a, 6
    ldh [hTimer], a
    ; Reset speed using .fallingEnd
    xor a, a
    jr .fallingEnd

.landing:
    ; -- landing --
    ldh a, [hTimer]
    dec a
    ldh [hTimer], a
    jr nz, .end
    ; Spawn a player
    call PlayerSpawn
    jr .end

.fallingEnd:
    ; Update the speed Y
    ldh [hSpeedY], a
.end:
    ; Update the Y position with the speed
    ld hl, wObjectPlayer + OAMA_Y
    ld b, [hl]
    ldh a, [hSpeedY]
    ; Shift the fractional bit off
    sra a
    add a, b
    ld [hl], a
    ; Update the player hair palette
    ld b, 1
    jp PlayerHairPalette


section union "Player HRAM", hram
hPlayerType: db
hState: db
hTimer: db
hTargetY: db
; Speed is stored with 7.1 precision since we only need to store .0 or .5
hSpeedY: db
