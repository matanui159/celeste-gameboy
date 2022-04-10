include "hardware.inc"

section "VBlank interrupt", rom0[$0040]
    jp VBlank

section "Video ROM", rom0


;; @param  c: Palette index register
;; @param  a: Destination palette address
;; @param hl: Source address
;; @param  b: Size
;; @effect c: Next index register
PaletteCopy::
    ; Add the auto-increment flag
    set BCPSB_AUTOINC, a
    ldh [c], a
    ; Get the data register
    inc c
.loop:
    ld a, [hl+]
    ldh [c], a
    dec b
    jr nz, .loop
    ; Get the next index register
    inc c
    ret


;; Initializes the video subsystem
VideoInit::
    ld c, low (rLCDC)
    ldh a, [c]
    bit LCDCB_ON, a ; LCDC_ON
    jr z, .off
    ; Wait for the next V-blank
    ld a, IEF_VBLANK
    ldh [rIE], a
    xor a, a
    ldh [rIF], a
    halt
    ; Clear the LCDC register
    ldh [c], a
.off:

    ; Copy over the tile data
    ld hl, _VRAM
    ld bc, GenTiles
    ld de, GenTiles.end - GenTiles
    call MemoryCopy

    ; Copy over the palettes
    ld c, low(rBCPS)
    ld a, $00
    ld hl, GenPalsBG
    ld b, GenPalsBG.end - GenPalsBG
    call PaletteCopy

    ld a, $00
    ld hl, GenPalsOBJ
    ld b, GenPalsOBJ.end - GenPalsOBJ
    call PaletteCopy

    ; Clear the video state
    xor a, a
    ldh [hVideoState], a
    ret


;; Waits for the next V-blank to render the frame
VideoDraw::
    ; TODO: wait for second v-blank before updating so input is more up-to-date
    ldh a, [hVideoState]
    set 1, a
    ldh [hVideoState], a
.loop:
    halt
    ldh a, [hVideoState]
    or a, a
    jr nz, .loop
    ; We reset the timer so we can measure how long updates take
    ldh [rDIV], a
    ret


section fragment "VBlank", rom0


;; The V-blank interrupt handler. We have this in a fragment section so that
;; Multiple source files can add to this code
VBlank:
    push af
    ldh a, [hVideoState]
    cp a, $03
    set 0, a
    jr nz, VBlankReturn
    ; We are in `VideoDraw` so we do not have to worry about saving registers
    ; Other pieces of fragment code will continue here


section "Video HRAM", hram
; bit 0: a singular frame has passed so the next frame will update and draw (to
;        limit to 30Hz)
; bit 1: updating is finished and the non-interrupt code is waiting for the next
;        draw to finish
; vblank sets bit 0 but will not update anything until both bit 0 and bit 1 are
; set
hVideoState:: db
