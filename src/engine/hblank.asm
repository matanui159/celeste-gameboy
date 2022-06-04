include "../hardware.inc"

section "STAT interrupt", rom0[$0048]
    jp wStat

section "HBlank ROM", rom0


;; Sets up an H-blank interrupt
;; @param  a: LY row
;; @param hl: Callback
HBlankSet::
    ldh [rLYC], a
    ; Save the address after the JP instruction
    ld a, l
    ld [wStat + 1], a
    ld a, h
    ld [wStat + 2], a
    ret


;; Updates the LCDC register when possible
;; @param a: New LCDC value
HBlankUpdateLCDC::
    ; Wait for the PPU to not be busy
    ld hl, rSTAT
.wait:
    bit STATB_BUSY, [hl]
    jr nz, .wait
    ; Update LCDC
    ldh [rLCDC], a
    ret


EnableObjects:
    push af
    push hl
    ; Enable objects
    ldh a, [rLCDC]
    set LCDCB_OBJON, a
    call HBlankUpdateLCDC
    ; Setup interrupt for drawing the timer at line 11
    ld a, 11
    ld hl, UIDrawTimer
    call HBlankSet
    pop hl
    pop af
    reti


HBlankDisableObjects::
    push af
    push hl
    ; Disable objects
    ldh a, [rLCDC]
    res LCDCB_OBJON, a
    call HBlankUpdateLCDC
    ; Setup interrupt for enabling objects at line 7
    ld a, 7
    ld hl, EnableObjects
    call HBlankSet
    pop hl
    pop af
    reti


;; Initializes the H-blank routines
HBlankInit::
    ; Setup the STAT interrupt for LYC
    ld a, STATF_LYC
    ldh [rSTAT], a
    ; Setup the STAT handler to be a JP instruction
    ld a, $c3
    ld [wStat], a
    ; Setup the first H-blank interrupt for enabling objects at line 7
    ld a, 7
    ld hl, EnableObjects
    jp HBlankSet


section "HBlank WRAM", wram0
wStat: ds 3
