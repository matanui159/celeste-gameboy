include "../hardware.inc"

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
    ld hl, wObjectsSmoke
    ld de, wObjects.end - wObjectsSmoke
    call MemoryClear

    ; Copy over the DMA function to HRAM
    ld hl, hObjectDMA
    ld bc, ObjectDMA
    ld de, hObjectDMA.end - hObjectDMA
    jp MemoryCopy


section fragment "VBlank", rom0
VBlankObjects:
    ld a, high(wObjectsSmoke)
    ; High byte is 41 wait loops, low byte is DMA register
    ; Despite what Pandocs says, this actually has to be 41 loops. The last
    ; iteration of the DMA function will run for 3 cycles instead of 4 making
    ; the entire wait loop be 159 cycles. Most emulators are fine with this due
    ; to the extra 4 cycles from the RET instruction, but Emulicious (which is
    ; apparently based on real hardware) fails, likely due to reading the stack
    ; early on in the RET instruction.
    ld bc, $2946
    call hObjectDMA


; These sections have specific addresses so we can keep the space between them
; empty
section "Objects WRAM", wram0[$c000]
wObjectsSmoke:: ds 10 * sizeof_OAM_ATTRS
.end::
wObjectPlayer:: ds sizeof_OAM_ATTRS
wObjectsFruit:: ds 3 * sizeof_OAM_ATTRS
wObjects:: ds 26 * sizeof_OAM_ATTRS
.end::

; Extra data for whatever purpose the object desires
section "Objects data", wram0[$c100]
wObjectsData:: ds OAM_COUNT * sizeof_OAM_ATTRS
.end::
