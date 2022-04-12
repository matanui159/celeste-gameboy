include "hardware.inc"

def SMOKE_COUNT equ 9

section "Smoke ROM", rom0


; TODO: this code is a mess LMAO


;; Initializes the smoke particle system
SmokeInit::
    ld a, low(wObjectPlayer) - 1
    ldh [hNextSmoke], a
    ret


;; Spawns a new smoke particle
;; @param bc: Position of smoke particle
SmokeSpawn::
    ; Get some random data
    push bc
    call Random
    pop bc
    ld d, a
    ; Get the next smoke address
    ld h, high(wObjectsSmoke)
    ldh a, [hNextSmoke]
    ld l, a
    ; Set random flip flags and palette
    ld a, d
    and a, OAMF_XFLIP | OAMF_YFLIP
    or a, 1
    ld [hl-], a
    ; Set tile
    ld a, 29
    ld [hl-], a
    ; Set position
    ; Use the lowest two random bits for X
    ld a, d
    and a, $03
    dec a
    add a, b
    ld [hl-], a
    ; Use the next two random bits for Y
    ld a, d
    rra
    rra
    and a, $03
    dec a
    add a, c
    ld [hl-], a

    ; Save the L address for the next smoke particle, wrap it with the lowest
    ; address
    ld a, l
    cp a, low(wObjectsSmoke)
    jr nc, .saveSmoke
    ld a, low(wObjectPlayer) - 1
.saveSmoke:
    ldh [hNextSmoke], a

    ; Setup address for writing meta data
    ld h, high(wSmokeData)
    inc l
    ; Write X speed from new random data
    push hl
    call Random
    pop hl
    ; Limit to range 0.3->0.55
    and a, $3f
    add a, 0.3 >> 8
    ld [hl+], a
    ; Clear X fractional remainder
    xor a, a
    ld [hl+], a
    ; Set tile counter to 5
    ld [hl], 5
    ret


;; Updates all the smoke particles
SmokeUpdate::
    ld hl, wObjectsSmoke
.loop:
    ; Check if the particle is still alive (tild ID != 0)
    inc l
    inc l
    ld a, [hl-]
    or a, a
    jr z, .next

    ; Update X movement using the speed and remainder
    ; Get the current X position and remainder
    ld b, [hl]
    ld h, high(wSmokeData)
    ld a, [hl-]
    ld c, a
    ; Get the X speed, saving L in register A
    ld a, l
    ld l, [hl]
    ld h, 0
    ; Calculate new X
    add hl, bc
    ld b, h
    ld c, l
    ; Save new X
    ld h, high(wObjectsSmoke)
    ld l, a
    inc l
    ld [hl], b
    ld h, high(wSmokeData)
    ld a, c
    ld [hl+], a

    ; Update tile ID using counter
    ld b, [hl]
    dec b
    jr nz, .counterEnd
    ; If the counter is 0, increment the tile ID and reset the counter
    ld h, high(wObjectsSmoke)
    ld a, [hl]
    inc a
    ; We reuse this counter to also increment Y, if two tiles have changed, (=31)
    ; then we move up 1 pixel
    ; TODO: I would feel better about this if we just had a remainder for Y as
    ;       well
    cp a, 31
    jr nz, .upEnd
    dec l
    dec l
    dec [hl]
    inc l
    inc l
.upEnd:
    ; Check if we reach tile 32
    cp a, 32
    jr c, .tileEnd
    ; If we have, destroy the object
    xor a, a
    dec l
    dec l
    ld [hl+], a
    inc l
.tileEnd:
    ld [hl], a
    ld h, high(wSmokeData)
    ld b, 5
.counterEnd:
    ld a, b
    ld [hl-], a
    ld h, high(wObjectsSmoke)

.next:
    ld a, l
    add a, 3
    ld l, a
    cp a, low(wObjectPlayer)
    jr c, .loop
    ret


section "Smoke WRAM", wram0, align[8, $04]
; Offset to align with the smoke objects
wSmokeData: ds SMOKE_COUNT * sizeof_OAM_ATTRS

section "Smoke HRAM", hram
hNextSmoke: db
