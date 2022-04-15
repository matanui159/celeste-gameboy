include "hardware.inc"

section "Header", rom0[$0100]
    jp Main
    ds $4d

section "Main ROM", rom0


;; The main entry point
Main:
    di
    ; Save the value A from the BIOS to later detect if we are CGB or DMG
    ldh [hMainBoot], a
    ; Setup stack to point to the top of memory
    ld sp, $e000

    call RandomInit
    call VideoInit
    call ObjectsInit
    call MapInit
    call SmokeInit

    ld a, IEF_VBLANK
    ldh [rIE], a
    xor a, a
    ldh [rIF], a
    ei

.loop:
    ; Add more entropy to the randomiser
    call Random
    call InputUpdate
    call PlayerUpdate
    call SmokeUpdate
    ; Wait for two frames so we run at 30Hz
    ld b, 2
    call VideoDraw
    jr .loop


section "Main HRAM", hram
hMainBoot:: db
