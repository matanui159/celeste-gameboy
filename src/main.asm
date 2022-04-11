include "hardware.inc"

section "Header", rom0[$0100]
    jp Main
    ds $4d

section "Main ROM", rom0


;; The main entry point
Main:
    di
    ; Setup stack to point to the top of memory
    ld sp, $e000

    call RandomInit
    call VideoInit
    call ObjectsInit
    call MapInit

    ld a, IEF_VBLANK
    ldh [rIE], a
    xor a, a
    ldh [rIF], a
    ei

.loop:
    ; Add more entropy to the randomiser
    call Random
    call MapUpdate
    call InputUpdate
    ; call player_update
    ; Wait for two frames so we run at 30Hz
    ld b, 2
    call VideoDraw
    jr .loop
