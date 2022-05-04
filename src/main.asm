include "hardware.inc"

section "Reset $38", rom0[$0038]
    ; We pad the ROM with $ff which is rst $38 so any invalid jumps will end up
    ; here. We just restart the ROM by restoring A and going back to the entry.
    ldh a, [hMainBoot]
    jp Entry

section "Header", rom0[$0100]


;; The entry-point of the ROM. We only have 4 bytes here so we disable interrupt
;; and jump somewhere else.
Entry:
    di
    jp Main

    ; We setup the charmap such that we can use spaces for empty bytes
charmap " ", 0
    ; Nintendo logo
    NINTENDO_LOGO
    ; Title
    db "CELESTE    "
    ; Manufacturer code, which the "Purpose and Deeper Meaning [is] unknown"
    ; Instead, we use it to indicate the open-source license
    db "MIT "
    ; CGB flag
    db CART_COMPATIBLE_DMG_GBC
    ; New license code, putting my initials here because I can :)
    db "JM"
    ; SGB flag
    db CART_INDICATOR_GB
    ; ROM type
    db CART_ROM_MBC5
    ; ROM size
    db CART_ROM_32KB
    ; RAM size
    db CART_SRAM_NONE
    ; Destination code
    db CART_DEST_NON_JAPANESE
    ; Old license code
    db $33
    ; Version (1.0)
    db $10
    ; Checksum
    ds 3
    ; Sneaking in a little backlink to the Github repo >_>
    db " https://github.com/matanui159/celeste-gameboy "


section "Main ROM", rom0


;; The main entry point
Main:
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
