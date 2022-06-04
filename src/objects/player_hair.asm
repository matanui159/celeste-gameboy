include "../hardware.inc"

section "Player hair ROM", rom0


;; Updates the players palette based on how many dashes they have
;; @param b: Dash count
PlayerHairPalette::
    ld hl, wObjectPlayer + OAMA_FLAGS
    ld a, [hl]
    and a, ~(OAMF_PAL1 | OAMF_PALMASK)
    ld c, a
    ; We can compare against one so we can check less-than (0), equal (1),
    ; or neither (2)
    ld a, b
    cp a, 1
    ; If the hair is blue, palette 0, we don't have to OR anything
    ; For DMG we do have to set PAL1, but lets just set that here :)
    set OAMB_PAL1, c
    jr c, .end
    jr z, .red
    ; Hair is flasing between between palette 2 and 3. On DMG we flash between
    ; white and dark grey.
    ; We can switch between palettes 1 and 2 by setting bit 1 and optionally
    ; setting bit 0
    ; We can use the same bit to switch between DMG palettes 0 and 1
    set 1, c
    ; Calculate the modulo 6 of the current frame to see if we need palette 2
    ; (<3) or palette 3 (>=3)
    ldh a, [hMainFrame]
    push bc
    call MathModuloSix
    pop bc
    cp a, 3
    jr c, .end
    ; If we want palette 3 we need to set bit 0. On DMG we want to remove the
    ; PAL1 flag. Luckily the red branch does both of this for us.
.red:
    ; Hair is red, palette 1 on CGB
    set 0, c
    ; Palette 0 on DMG
    res OAMB_PAL1, c
.end:
    ; Save back the attributes and DMG palette
    ld [hl], c
    ret
