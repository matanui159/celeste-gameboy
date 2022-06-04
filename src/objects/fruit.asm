include "fruit.inc"
include "../hardware.inc"

section "Fruit ROM", rom0


;; Removed any fruit-related object
FruitClear::
    ; Set the fruit type to NONE (0)
    xor a, a
    ldh [hFruitType], a
    ret


;; Spawns a fruit at the given position
;; @param bc: Fruit position
FruitSpawn::
    ; Save the starting Y position
    ld a, c
    ldh [hStartY], a
    ld hl, wObjectsFruit
    ; Y
    ld a, c
    ld [hl+], a
    ; X
    ld a, b
    ld [hl+], a
    ; Tile ID
    ld a, 26
    ld [hl+], a
    ; Attributes and palette
    ld [hl], 5
    ; Sets the fruit type to NORMAL
    ld a, FRUIT_NORMAL
    ldh [hFruitType], a
    ret


;; Loads a fruit by itself in a map
;; @param hl: Tile address
FruitLoad::
    ; Remove the tile
    xor a, a
    ld [hl], a
    ; Check if the fruit has already been collected
    ldh a, [hFruitCollected]
    or a, a
    ret nz
    ; Get the position
    call MapTilePosition
    ; Spawn the fruit
    push hl
    call FruitSpawn
    pop hl
    ret


;; Updates the fruit objects
FruitUpdate::
    ; Ignore this update if there are skip frames
    ldh a, [hFruitSkip]
    or a, a
    jr z, .skipEnd
    ; Decrement the skip frames and return
    dec a
    ldh [hFruitSkip], a
    ret
.skipEnd:
    ; Check the fruit type to see which routine we need to call
    ldh a, [hFruitType]
    cp a, FRUIT_NORMAL
    ; If there is no fruit (NONE) or its a tile (FAKE_WALL), skip the update
    ret c
    ; If its a normal fruit, we're already in the correct routine
    jr z, .updateNormal
    cp a, FRUIT_LIFEUP
    ; TODO: support flying fruit
    ret c
    jp z, LifeupUpdate
    ; TODO: support chests and key
    ret

.updateNormal:
    ; Get the sine wave, multiply by 3
    ldh a, [hMainFrame]
    ld b, a
    add a, a
    add a, b
    call MathSin
    ; We treat the number as a 1.7 signed number
    ; To multiply against 2.5 first we multiply it aginst (2.5 / 4)
    sra a
    ld b, a
    sra a
    sra a
    add a, b
    ; Then we multiply by 4 while also removing the 7 sign bits, resulting in a
    ; shift of 5
rept 5
    sra a
endr
    ; Add to the start Y position
    ld b, a
    ldh a, [hStartY]
    add a, b
    ; Save the new Y position
    ld hl, wObjectsFruit
    ld [hl+], a

    ; Get the X and Y position
    ld b, [hl]
    ld c, a
    ; Check if it collides with the player
    ld de, $0808
    call PhysicsCheckPlayer
    or a, a
    ; End now if it doesn't
    ret z
    ; Reset the player dash count
    ; TODO: we really gotta get ourselves a max dashes variable
    ld a, 1
    ldh [hPlayerDashCount], a
    ; Mark the fruit as collected so it doesn't respawn
    ; ld a, 1
    ldh [hFruitCollected], a
    ; Start the lifeup animation
    call LifeupSpawn
    ; Play a sound, JP so it returns afterwards
    ld a, 13
    jp AudioPlaySound


section "Fruit common HRAM", hram
hFruitType:: db
hFruitCollected:: db
hFruitSkip:: db

section union "Fruit HRAM", hram
hStartY: db
