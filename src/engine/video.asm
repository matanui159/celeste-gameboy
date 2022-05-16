include "../hardware.inc"

section "VBlank interrupt", rom0[$0040]
    jp VBlank

section "Video ROM", rom0


;; Wait for the start of the next V-blank
VideoWait::
    ; First check if the LCD is enabled, if not return immediately
    ldh a, [rLCDC]
    bit LCDCB_ON, a
    ret z

    ; Busy loop until first line of V-blank
    ld a, SCRN_Y
    ld hl, rLY
.loop:
    cp a, [hl]
    jr nz, .loop
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
    call VideoWait
    xor a, a
    ldh [rLCDC], a

    ; Copy over the tile data
    ld hl, _VRAM
    ld bc, GenTiles
    ld de, GenTiles.end - GenTiles
    call MemoryCopy

    ; Copy over the bitmap data
    ; HL is already at the correct address
    ld bc, Bitmaps
    ; We count the number of tiles with each tile being 8 bytes
    ld d, (BitmapsEnd - Bitmaps) / 8
.bitmapLoop:
    ; Copy one tile, we convert 1bpp to 2bpp by duplicating the single byte per
    ; row
rept 8
    ld a, [bc]
    inc bc
    ld [hl+], a
    ld [hl+], a
endr
    dec d
    jr nz, .bitmapLoop

    ; Check if we are on CGB or DMG
    ldh a, [hMainBoot]
    cp a, BOOTUP_A_CGB
    jr z, .cgbPalettes

    ; Setup DMG palettes
    ; The palette we use is inverse of the default DMG palette where 11 is white
    ; and 00 is black.
    ld a, %00_01_10_11
    ldh [rBGP], a
    ldh [rOBP0], a
    ldh [rOBP1], a
    jr .palettesEnd

.cgbPalettes:
    ; Copy over the CGB palettes
    ld c, low(rBCPS)
    ld a, $00
    ld hl, GenPalettesBG
    ld b, GenPalettesBG.end - GenPalettesBG
    call PaletteCopy

    ld a, $00
    ld hl, GenPalettesOBJ
    ld b, GenPalettesOBJ.end - GenPalettesOBJ
    call PaletteCopy

.palettesEnd:

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
    ld hl, hVideoFrames
    ; Reset the frame count
    xor a, a
    ld [hl], a
    ; We move B to A and decrement such that the carry flag (A < [HL]) is
    ; set when [HL] becomes B or higher
    ld a, b
    dec a
.loop:
    halt
    cp a, [hl]
    jr nc, .loop
    ret


section fragment "VBlank", rom0


;; The V-blank interrupt handler. We have this in a fragment section so that
;; Multiple source files can add to this code
VBlank:
    push af
    ldh a, [hVideoFrames]
    or a, a
    jr nz, VBlankReturn
    ; While we are likely in `VideoDraw` so we could just save the registers it
    ; uses, the audio interrupt could also be running right now, so we save
    ; everything that is used by this interrupt.
    push bc
    push hl
    ; Other pieces of fragment code will continue here, ending with
    ; `fragment.asm`


section "Video WRAM", hram
; A frame count incremented by the VBlank handler and gets reset every update
; Renders only occur on frame 0
hVideoFrames:: db
