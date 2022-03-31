include "reg.inc"
include "util.inc"

section "header_rom", rom0[$0100]
    nop
    jp main
    ds $4c

section "main_rom", rom0


; () => void
main:
    di
    ; reset memory
    xor a, a
    ld hl, $c000
    ld b, a
.clear:
rept $20
    ld [hl+], a
endr
    dec b
    jr nz, .clear
    ; setup stack
    ld sp, $e000

    call video_init
    call map_init
    call objects_init

    MV8 [REG_LCDC], LCDC_BG_DATA0 | LCDC_OBJ_ON | LCDC_ON
    MV8 [REG_IE], INT_VBLANK
    MV0 [REG_IF]
    ei

.loop:
    call input_update
    call player_update
    call video_draw
    jr .loop
