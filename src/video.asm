include "hardware.inc"

section "VBlank interrupt", rom0[$0040]
    jp VBlank

section "Video ROM", rom0


;; Wait for a chance to disable the LCD and disable it
VideoDisable::
    ; First check if the LCD is enabled, if not return immediately
    ldh a, [rLCDC]
    bit LCDCB_ON, a
    ret z

    ; Busy loop until first line of V-blank
    ld a, 144
    ld hl, rLY
.loop:
    cp a, [hl]
    jr nz, .loop

    ; Disable LCD
    xor a, a
    ldh [rLCDC], a
    ret


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
    ; Disable the LCD so we can safely work on it
    call VideoDisable

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

    ; Set 1 frame so it won't draw until the first `VideoDraw` call
    ld a, 1
    ldh [hVideoFrames], a
    ; We don't have to re-enable LCD cause a later call to MapInit will do that
    ; for us
    ret


;; Waits for a specified amount of V-blanks, the first of which renders the
;; frame
;; @param b: The amount of frames to wait
VideoDraw::
    ld c, low(hVideoFrames)
    ; Reset the frame count
    xor a, a
    ldh [c], a
.loop:
    halt
    ldh a, [c]
    cp a, b
    jr c, .loop
    ret


section fragment "VBlank", rom0


;; The V-blank interrupt handler. We have this in a fragment section so that
;; Multiple source files can add to this code
VBlank:
    push af
    ldh a, [hVideoFrames]
    or a, a
    jr nz, VBlankReturn
    ; We are in `VideoDraw` so we know which exact registers we need to save
    push bc
    ; Other pieces of fragment code will continue here, ending with
    ; `fragment.asm`


section "Video WRAM", hram
; A frame count incremented by the VBlank handler and gets reset every update
; Renders only occur on frame 0
hVideoFrames:: db
