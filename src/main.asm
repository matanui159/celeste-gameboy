include "hardware.inc"

section "Header", rom0[$0100]
    jp Main
    ds $4d

section "Main ROM", rom0


;; The main entry point
Main:
    ; reset memory
    ; TODO: remove this when respective parts of the code do this themselves
    ld hl, $c000
    ld de, $2000
    call MemoryClear
    ; Setup stack to point to the top of memory
    ld sp, $e000

    call RandomInit
    call VideoInit
    call map_init
    call ObjectsInit

    ld a, LCDCF_BGON | LCDCF_OBJON | LCDCF_BG8000 | LCDCF_ON
    ldh [rLCDC], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    xor a, a
    ldh [rIF], a
    ei

.loop:
    ; Add more entropy to the randomiser
    call Random

    call InputUpdate
    call player_update
    call VideoDraw
    jr .loop
