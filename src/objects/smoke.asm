include "../hardware.inc"

section "Smoke ROM", rom0


;; Initializes the smoke particle system
SmokeInit::
    ld a, low(wObjectsSmoke.end)
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
    dec l
    ; Set random flip flags and palette
    ld a, d
    and a, OAMF_XFLIP | OAMF_YFLIP
    or a, 1
    ld [hl-], a
    ; Set tile
    ld a, 29
    ld [hl-], a
    ; Set position
    ; Use the lowest random bit for X
    ; We use an offset of -1<=x<=0 with which the random remainder below becomes
    ; -1<=x<1
    ld a, d
    and a, $01
    dec a
    add a, b
    ld [hl-], a
    ; Use the next random bit for Y
    ld a, d
    rra
    and a, $01
    dec a
    add a, c
    ld [hl], a

    ; Save the L address for the next smoke particle, wrap it with the lowest
    ; address
    ld a, l
    or a, a
    jr nz, .saveSmoke
    ld a, low(wObjectsSmoke.end)
.saveSmoke:
    ldh [hNextSmoke], a

    ; Swap to object data
    inc h
    ; Write X and Y remainders using random data
    push hl
    call Random
    pop hl
    ld [hl+], a
    push hl
    call Random
    pop hl
    ld [hl+], a
    ; Setup tile counter
    ld a, 5
    ld [hl+], a
    ; Write X speed from even more random data
    push hl
    call Random
    pop hl
    ; Limit to range 0.3->0.55
    and a, $3f
    add a, 0.3 >> 8
    ld [hl+], a
    ret


;; Updates all the smoke particles
SmokeUpdate::
    ld hl, wObjectsSmoke.end
.loop:
    ; Check if the particle is still alive (tild ID != 0)
    dec l
    dec l
    ld a, [hl]
    or a, a
    jr nz, .update
    dec l
    dec l
    jr nz, .loop
    ret

.update:
    ; Update tile ID using the counter
    ; INC swaps to the object's data, DEC swaps back
    inc h
    ld b, [hl]
    dec b
    jr nz, .counterEnd
    ; If the counter is 0, increment the tile ID and reset the counter
    ; We still have the tile ID in register A from above
    inc a
    ; Check if we reach tile 32, destroy the object if we have, skipping the
    ; rest of the update
    cp a, 32
    jr nc, .destroy
    ; Save the new tile
    dec h
    ld [hl], a
    inc h
    ld b, 5
.counterEnd:
    ld a, b
    ld [hl-], a

    ; Update the X movement, using the random speed
    ; Load X position
    ; Save HL into DE for later. We also use it to get the high-byte
    ld d, h
    ld e, l
    ; Low byte
    ld a, [hl+]
    ld c, a
    ; High byte
    dec d
    ld a, [de]
    ld b, a
    ; Load random X speed
    inc l
    ld l, [hl]
    ld h, 0
    ; Add speed, saving into BA
    add hl, bc
    ld b, h
    ld a, l
    ; Save X position
    ld h, d
    ld l, e
    ld [hl], b
    inc h
    ld [hl-], a

    ; Update Y movement using a fixed speed of -0.1 and Y remainder
    ; Read the Y position and remainder
    ; Save HL for later
    ld d, h
    ld e, l
    ld c, [hl]
    dec h
    ld b, [hl]
    ; Add the speed, store into AC
    ld hl, -(0.1 >> 8)
    add hl, bc
    ld a, h
    ld c, l
    ; Write the new Y and remainder
    ld h, d
    ld l, e
    ld [hl], c
    dec h
    ; We use HL+ so we can DEC below to quickly check L
    ld [hl+], a

    ; Continue the loop
    dec l
    jr nz, .loop
    ret

.destroy:
    ; Destroy the object and continue the loop
    xor a, a
    dec h
    ; Set tile ID to 0
    ld [hl-], a
    dec l
    ; Set Y position to 0
    ld [hl], a
    jr nz, .loop
    ret


section "Smoke HRAM", hram
hNextSmoke: db
