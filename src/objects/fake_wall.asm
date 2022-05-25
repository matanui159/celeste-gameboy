include "fruit.inc"
include "../attrs.inc"

section "Fake wall ROM", rom0


;; @param hl: Tile address
;; @saved hl
FakeWallLoad::
    ; Check if we should load this fake wall
    ldh a, [hFruitCollected]
    or a, a
    jr z, .loadWall
    ; Clear out this tile so the wall does not exist at all
    xor a, a
    ld [hl], a
    ret

.loadWall:
    ; Save L so we can restore it later
    ld b, l
    ; Save the top-right tile and replace it with tile 65
    inc l
    ld a, [hl]
    ldh [hTopRightTile], a
    ld [hl], 65
    ; Save the bottom-right tile
    ld a, l
    add a, $10
    ld l, a
    ld a, [hl]
    ldh [hBottomRightTile], a
    ld [hl], 81
    ; Save the bottom-left tile
    dec l
    ld a, [hl]
    ldh [hBottomLeftTile], a
    ld [hl], 80
    ; Restore L
    ld l, b
    ret


;; Handles collision with the top-left tile
;; @param bc: Collide position
;; @saved hl
;; @saved bc
;; @saved de
FakeWallCollideTopLeft::
    push hl
    call MapFindTileAt
    jr WallCollide


;; Handles collision with the top-right tile
;; @param bc: Collide position
;; @saved hl
;; @saved bc
;; @saved  d
FakeWallCollideTopRight::
    push hl
    call MapFindTileAt
    dec l
    jr WallCollide


;; Handles collision with the bottom-left tile
;; @param bc: Collide position
;; @saved hl
;; @saved bc
;; @saved  d
FakeWallCollideBottomLeft::
    push hl
    call MapFindTileAt
    ld a, l
    sub a, $10
    ld l, a
    jr WallCollide


;; Handles collision with the bottom-right tile
;; @param bc: Collide position
;; @saved hl
;; @saved bc
;; @saved  d
FakeWallCollideBottomRight::
    push hl
    call MapFindTileAt
    ld a, l
    sub a, $11
    ld l, a
    ; Falls through to `WallCollide`


;; Common code shared by all collision routines
;; @param hl: Tile address
;; @returns hl: Popped off stack
;; @saved bc
;; @saved  d
WallCollide:
    ; Treat the wall as solid if we are not dashing
    ldh a, [hPlayerDashTime]
    or a, a
    jr z, .solid
    push bc
    push de

    ; Clear the players dash-time
    xor a, a
    ldh [hPlayerDashTime], a
    ; Remove the fake-wall, replacing with whatever tiles were there to begin
    ; with
    ; For the top left tile, where the initial fake-wall was, the tile "behind"
    ; it is always 0
    push hl
    call MapTileUpdate
    pop hl
    ; Top-right tile
    inc l
    ldh a, [hTopRightTile]
    push hl
    call MapTileUpdate
    pop hl
    ; Bottom-right tile
    ld a, l
    add a, $10
    ld l, a
    ldh a, [hBottomRightTile]
    push hl
    call MapTileUpdate
    pop hl
    ; Bottom-left tile
    dec l
    ldh a, [hBottomLeftTile]
    push hl
    call MapTileUpdate
    pop hl

    ; Get the tile position (of the bottom-left tile)
    call MapTilePosition
    ; Bottom left smoke particle
    push bc
    call SmokeSpawn
    pop bc
    ; Bottom right smoke particle
    ld a, b
    add a, 8
    ld b, a
    push bc
    call SmokeSpawn
    pop bc
    ; Top right smoke particle
    ld a, c
    sub a, 8
    ld c, a
    push bc
    call SmokeSpawn
    pop bc
    ; Top left smoke particle
    ld a, b
    sub a, 8
    ld b, a
    call SmokeSpawn

    ; Read the player X speed
    ld hl, wPlayerSpeedX + 1
    ld a, [hl-]
    ld b, a
    ld c, [hl]
    ; Check if the speed is zero
    ; The high byte is already in A
    or a, a
    jr nz, .speedNonZeroX
    ; A is now zero, so we can easily compare against C
    cp a, c
    ; If the X speed is zero, no changes are made
    jr z, .speedEndX
.speedNonZeroX:
    ; Switch between -1.5 or 1.5 depending on if the speed is negative or not
    bit 7, b
    ld bc, -(1.5 >> 8)
    jr z, .speedEndX
    ; Speed is negative, swap to positive
    ld bc, 1.5 >> 8
.speedEndX:
    ; Save the new speed X
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ; Save -1.5 as the new Y speed
    ld a, low(-(1.5 >> 8))
    ld [hl+], a
    ld [hl], high(-(1.5 >> 8))

    ; PLay a sound effect for finding the hidden fruit
    ld a, 16
    call AudioPlaySound
    pop de
    pop bc
    jr .return
.solid:
    ; Mark the tile as solid
    set ATTRB_SOLID, d
.return:
    pop hl
    ret


section union "Fruit HRAM", hram
hTopRightTile: db
hBottomLeftTile: db
hBottomRightTile: db
