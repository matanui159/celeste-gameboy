include "../hardware.inc"


section "STAT interrupt", rom0[$0048]
    ; Save some variables onto the stack, and jump somewhere else
    ; We set the specific address for that "somewhere else" so that we can use
    ; A relative jump.
    push af
    push hl
    jr Stat


section "STAT ROM", rom0[$0066]
Stat:
    ; Toggle the objects, save into H for now
    ldh a, [rLCDC]
    xor a, LCDCF_OBJON
    ld h, a
    ; Update the LYC, starting at the current SCY
    ldh a, [rSCY]
    cpl
    ; If the objects are now enabled, we wanna setup LYC later to disable it
    bit LCDCB_OBJON, h
    jr z, .updateLYC
    ; Bottom of the map
    add a, 128
.updateLYC:
    ldh [rLYC], a

    ; Wait for when we can safely update LCDC
    ld a, h
    ld hl, rSTAT
.wait:
    bit STATB_BUSY, [hl]
    jr nz, .wait
    ; Update LCDC and return
    ldh [rLCDC], a
    pop hl
    pop af
    reti


section "HBlank ROM", rom0


;; Initializes the H-blank routines
HBlankInit::
    ; Setup the LY interrupt line to be SCY-1. Note that SCY is negative
    ldh a, [rSCY]
    cpl
    ; The increment for negating and the decrement for LYC cancel out
    ldh [rLYC], a
    ; Setup the STAT interrupt for LYC
    ld a, STATF_LYC
    ldh [rSTAT], a
    ret
