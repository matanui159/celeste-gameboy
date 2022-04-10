include "hardware.inc"

section "Objects ROM", rom0


;; @param c: DMA register
;; @param a: Source high address
;; @param b: Wait time
ObjectDMA:
load "Object DMA", hram
hObjectDMA:
    ldh [c], a
.loop:
    dec b
    jr nz, .loop
    ret
.end:
endl


;; Initializes the object rendering
ObjectsInit::
    ; Copy over the DMA function to HRAM
    ld hl, hObjectDMA
    ld bc, ObjectDMA
    ld de, hObjectDMA.end - hObjectDMA
    jp MemoryCopy


section fragment "VBlank", rom0
    ld a, high(wObjectSnow)
    ; High byte is 40 wait loops, low byte is DMA register
    ld bc, $2846
    call hObjectDMA


section "Object WRAM", wram0, align[8]
wObjectSnow:: ds sizeof_OAM_ATTRS
wObjectsSmoke:: ds 9 * sizeof_OAM_ATTRS
wObjectPlayer:: ds sizeof_OAM_ATTRS
wObjectsFruit:: ds 3 * sizeof_OAM_ATTRS
wObjects:: ds 26 * sizeof_OAM_ATTRS
