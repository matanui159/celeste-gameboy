include "player.inc"
include "../hardware.inc"

section "Player death ROM", rom0


;; Kills the player and spawns the death particles. Can be considered as a
;; `PlayerDeathSpawn` but that makes no sense.
;; Like PlayerSpawn, does not take arguments and instead uses the current
;; player position.
PlayerDeathKill::
    ld hl, wObjectPlayer
    ; For the first sprite, just swap out the sprite while getting the position
    ; and palette
    ; We don't offset the position since all the sprites are centered
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    ; The square sprites start at $80, we want the largest size
    ld a, $83
    ld [hl+], a
    ld a, [hl+]
    ld d, a

    ; Save the current palette
    and a, OAMF_PALMASK
    ; If the palette is white, force it to be green since we'll be flashing to
    ; white anyway
    cp a, 2
    jr nz, .paletteEnd
    ; Also set the palettte in D and [HL]
    ld a, d
    or a, $01
    ld d, a
    dec l
    ld [hl+], a
    and a, OAMF_PALMASK
.paletteEnd:
    ldh [hPalette], a

    ; Setup the other 7 objects as basically copies of the first one
    ld e, 7
.objectLoop:
    ; Y
    ld a, c
    ld [hl+], a
    ; X
    ld a, b
    ld [hl+], a
    ; Tile ID
    ld a, $83
    ld [hl+], a
    ; Attributes
    ld a, d
    ld [hl+], a
    dec e
    jr nz, .objectLoop

    ; Set the player type to death
    ld a, PLAYER_DEATH
    ldh [hPlayerType], a
    ; Setup the death timer
    ld a, 15
    ldh [hTimer], a

    ; Play the death sound, high priority
    ld a, 0
    jp AudioPlaySound


;; Updates a singular death particle
;; @param hl: Pointer to the object
;; @param bc: Particle speed
;; @param  d: New particle sprite
;; @effect hl: Pointer to the next object
;; @saved bc
;; @saved  d
UpdateDeathParticle:
    ; Update Y position
    ld a, [hl]
    add a, c
    ld [hl+], a
    ; Update X position
    ld a, [hl]
    add a, b
    ld [hl+], a
    ; Update the tile
    ld a, d
    ld [hl+], a
    ; Toggle the palette
    ldh a, [hPalette]
    xor a, [hl]
    ; Palette for white
    xor a, 2
    ld [hl+], a
    ret


;; Updates the death animation
PlayerDeathUpdate::
    ; Decrement the timer
    ldh a, [hTimer]
    dec a
    ldh [hTimer], a
    ; If it is now zero, restart the room
    ld b, a
    ldh a, [hMapIndex]
    jp z, MapLoad

    ; Subtract 5 to see the particle timer
    ld a, b
    sub a, 5
    jr z, .destroy
    ; Skip animation if the particles are already destroyed
    ret c
    ; Get the next sprite based on the timer
    ; The timer is now in the range 9->1, so we can decrement and subtract 1 to
    ; get 4->0. In the special case of 4 we just set it to 3.
    dec a
    ; DEC doesn't set carry and we would return if SUB set carry
    rra
    ; Just because I feel like being fancy today, we can decrement all numbers
    ; and use ADC to increment 0-3 by comparing to 4 (which would set carry).
    ; All these can be included in a singular instruction since the decrement
    ; can be included in the +$80 and the ADC is already an addition
    cp a, 4
    adc a, $7f
    ld d, a

    ld hl, wObjectPlayer
    ; East
    ld b, 3
    ld c, 0
    call UpdateDeathParticle
    ; West
    ld b, -3
    call UpdateDeathParticle
    ; South-West
    inc b
    ld c, 2
    call UpdateDeathParticle
    ; South-East
    ld b, 2
    call UpdateDeathParticle
    ; North-East
    ld c, -2
    call UpdateDeathParticle
    ; North-West
    ld b, -2
    call UpdateDeathParticle
    ; North
    ld b, 0
    dec c
    call UpdateDeathParticle
    ; South
    ld c, 3
    call UpdateDeathParticle

    ; Check if we are on DMG
    ldh a, [hMainBoot]
    cp a, BOOTUP_A_CGB
    ret z
    ; If we are, we want the particles to flash between dark grey and white.
    ; To do this we reuse the hair code since that is able to update the DMG
    ; palette. We switch between 0 and 1 dashes, using the timer.
    ldh a, [hTimer]
    and a, $01
    ld b, a
    jp PlayerHairPalette

.destroy:
    ; If the timer is exactly 5, destroy the particles
    xor a, a
    ld hl, wObjectPlayer
    ld b, 16
.destroyLoop:
    ld [hl+], a
    inc l
    dec b
    jr nz, .destroyLoop
    ret


section union "Player HRAM", hram
hTimer: db
; The color of the players palette upon death
hPalette: db
