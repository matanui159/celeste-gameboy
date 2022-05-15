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
    ; Toggle the LY register. If this interrupt is for 7, we switch to 128+7,
    ; otherwise switch back to 7.
    ldh a, [rLYC]
    xor a, 128
    ldh [rLYC], a
    ; Toggle the objects
    ldh a, [rLCDC]
    xor a, LCDCF_OBJON
    ; Wait for when we can safely update LCDC
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
    ; Setup the LY interrupt line to be 7
    ld a, 7
    ldh [rLYC], a
    ; Setup the STAT interrupt for LYC
    ld a, STATF_LYC
    ldh [rSTAT], a
    ret
