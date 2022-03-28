include "reg.inc"
include "util.inc"

section "object_rom", rom0


; () => void
objects_draw_rom:
load "object_hram", hram
objects_draw::
    LDA [REG_DMA], high(object_smoke)
    ld a, $40
.loop:
    dec a
    jr nz, .loop
    ret
.end:
endl


; () => void
objects_init::
    ld c, low(objects_draw)
    ld hl, objects_draw_rom
    ld b, objects_draw.end - objects_draw
.loop:
    LDA [c], [hl+]
    inc c
    dec b
    jr nz, .loop

    ; use DMA now to clear OAM
    jp objects_draw


section "object_wram", wram0, align[8]
object_snow:: ds OAM_SIZE
object_smoke:: ds 9 * OAM_SIZE
object_player:: ds OAM_SIZE
object_fruit:: ds 3 * OAM_SIZE
objects:: ds 26 * OAM_SIZE
