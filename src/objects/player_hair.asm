include "../hardware.inc"

section "Player hair ROM", rom0


;; Performs modulo 6 on an 8-bit value
;; @param a: Input value
;; @param a: Modulo 6 of the input
ModuloSix:
    ; Modulo values for each bit are:
    ;  0:  1
    ;  1:  2
    ;  2: -2
    ;  3:  2
    ;  4: -2
    ;  5:  2
    ;  6: -2
    ;  7:  2
    ; We can leave the lower 2 bits as is
    ld b, a
    and a, $03
    srl b
    srl b
    ld c, a
    ; Decrement for each even bit and increment for each odd bit
    xor a, a
    ; Save zero into D so we can use it in ADC later
    ld d, a
rept 3
    srl b
    sbc a, d
    srl b
    adc a, d
endr
    ; Times by 2 (since each inc/dec is +/-2) and add the low 2 bits
    add a, a
    add a, c
    ; Handle negative values
    bit 7, a
    jr nz, .neg
    ; If the value is <6 we can return now
    cp a, 6
    ret c
    ; Otherwise, subtract 6
    sub a, 6
    ret
.neg:
    ; If the value is negative, return 6+A
    add a, 6
    ret


;; Updates the players palette based on how many dashes they have
;; @param b: Dash count
PlayerHairPalette::
    ld hl, wObjectPlayer + OAMA_FLAGS
    ld a, [hl]
    and a, ~OAMF_PALMASK
    ld d, a
    ; We can compare against one so we can check less-than (0), equal (1),
    ; or neither (2)
    ld a, b
    cp a, 1
    ; If the hair is blue, palette 0, we don't have to OR anything
    ; For DMG we do have to set D, but lets just set that here :)
    ld e, %10_01_10_11
    jr c, .end
    jr z, .red
    ; Hair is flasing between between palette 2 and 3. On DMG we flash between
    ; white and dark grey.
    ; We can switch between palettes 1 and 2 by setting bit 1 and optionally
    ; setting bit 0
    set 1, d
    ; Calculate the modulo 6 of the current frame to see if we need palette 2
    ; (<3) or palette 3 (>=3)
    ldh a, [hMainFrame]
    push de
    call ModuloSix
    pop de
    cp a, 3
    jr c, .end
    ; If we want palette 3 we need to set bit 0. On DMG we want to swap the
    ; highest color to white. Luckily the red branch does both of this for us.
.red:
    ; Hair is red, palette 1. On DMG we set the highest color to white.
    set 0, d
    ld e, %00_01_10_11
.end:
    ; Save back the attributes and DMG palette
    ld [hl], d
    ld a, e
    ldh [hDMGPalette], a
    ret


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


section "Player hair HRAM", hram
hDMGPalette: db
