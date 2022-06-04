include "fruit.inc"

section "Lifeup ROM", rom0


;; Spawns the lifeup animation. Doesn't take any inputs and assumes the fruit is
;; already in the correct position.
LifeupSpawn::
    ld hl, wObjectsFruit
    ; Left object
    ; Y, shifted up by 4
    ld a, [hl]
    sub a, 4
    ld [hl+], a
    ; Save Y position for later
    ld c, a
    ; X, shifted left by 4
    ld a, [hl]
    sub a, 4
    ld [hl+], a
    ; Shift X right by 8 for later
    add a, 8
    ld b, a
    ; Tile ID, '10'
    ld a, 10 + $84
    ld [hl+], a
    ; Attributes and palette, we reuse player hair colors for the flashing
    ld a, 1
    ld [hl+], a

    ; Right object
    ; Y
    ld a, c
    ld [hl+], a
    ; X
    ld a, b
    ld [hl+], a
    ; Tile ID, '00'
    ld a, 0 + $84
    ld [hl+], a
    ; Attributes and palette
    ld a, 1
    ld [hl+], a

    ; Third object, unused
    xor a, a
    ld [hl+], a
    inc l
    ld [hl+], a
    ; Set the fruit type to LIFEUP
    ld a, FRUIT_LIFEUP
    ldh [hFruitType], a
    ; Setup the animation timer
    ld a, 30
    ldh [hTimer], a
    ret


;; Updates the lifeup animation
LifeupUpdate::
    ; Setup the object pointer now
    ld hl, wObjectsFruit
    ; Decrement the timer
    ldh a, [hTimer]
    dec a
    jr z, .destroy
    ldh [hTimer], a

    ; Update the Y position
    ld c, [hl]
    ; If the lower two bits of the timer are 0, we move up one pixel
    ; (every 4 frames)
    and a, $03
    or a, a
    jr nz, .moveEndY
    dec c
.moveEndY:
    ; Calculate the palette while we have A, move into B
    ; OR sets carry to 0 and INC doesn't overwrite carry
    rra
    ; On CGB we switch between palettes 1 and 2
    ld b, a
    inc a
    ; On DMG we use this bit in the PAL position
    swap b
    or a, b
    ld b, a
    ; Save the Y position
    ld a, c
    ld [hl+], a
    ; Save the palette
    inc l
    inc l
    ld a, b
    ld [hl+], a
    ; Do the same for the right tile
    ld a, c
    ld [hl+], a
    inc l
    inc l
    ld [hl], b
    ret

.destroy:
    ; If the timer is done, destroy the lifeup animation
    xor a, a
rept 4
    ld [hl+], a
    inc l
endr
    ; Set the fruit type to NONE
    ldh [hFruitType], a
    ret


section union "Fruit HRAM", hram
hTimer: db
