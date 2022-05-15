include "hardware.inc"

section "Reset $30", rom0[$0030]
    ; A little utility which will JP to HL. Since RST calls are like normal
    ; calls this allows for a 1-byte CALL HL
    jp hl

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
    ; Instead, I'm using it to indicate the open-source license
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
    ; Switch to this ROM size to support the PNG wrapper
    ; db CART_ROM_128KB
    ; RAM size
    db CART_SRAM_NONE
    ; Destination code
    db CART_DEST_NON_JAPANESE
    ; Old license code
    db $33
    ; Version (0.1)
    db $01
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
    ; Reset the frame counter
    xor a, a
    ldh [hMainFrame], a

    call RandomInit
    call VideoInit
    call ObjectsInit
    call MapInit
    call SmokeInit
    call HBlankInit
    call InputInit
    call AudioInit

    ld a, IEF_VBLANK | IEF_STAT | IEF_TIMER
    ldh [rIE], a
    xor a, a
    ldh [rIF], a
    ei

.loop:
    ; Increment the frame counter
    ld hl, hMainFrame
    inc [hl]
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
hMainFrame:: db
