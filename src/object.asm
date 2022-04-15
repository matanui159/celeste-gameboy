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
    ; Clear the OAM source
    ld hl, wObjectSnow
    ld de, wObjects.end - wObjectSnow
    call MemoryClear

    ; Copy over the DMA function to HRAM
    ; Instead of using MemoryCopy we can make it faster with LDH and REPT
    ld c, low(hObjectDMA)
    ld hl, ObjectDMA
rept hObjectDMA.end - hObjectDMA
    ld a, [hl+]
    ldh [c], a
    inc c
endr
    ret


section fragment "VBlank", rom0
VBlankObjects:
    ld a, high(wObjectSnow)
    ; High byte is 40 wait loops, low byte is DMA register
    ld bc, $2846
    call hObjectDMA


; These sections have specific addresses so we can keep the space between them
; empty
section "Objects WRAM", wram0[$c000]
wObjectSnow:: ds sizeof_OAM_ATTRS
wObjectsSmoke:: ds 9 * sizeof_OAM_ATTRS
.end::
wObjectPlayer:: ds sizeof_OAM_ATTRS
wObjectsFruit:: ds 3 * sizeof_OAM_ATTRS
wObjects:: ds 26 * sizeof_OAM_ATTRS
.end::

; Extra data for whatever purpose the object desires
section "Objects data", wram0[$c100]
wObjectsData:: ds OAM_COUNT * sizeof_OAM_ATTRS
.end::
