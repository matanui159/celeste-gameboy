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

    LDA [REG_LCDC], LCDC_BG_DATA0 | LCDC_OBJ_ON | LCDC_ON
    LDA [REG_IE], INT_VBLANK
    LDZ [REG_IF]
    ei

.loop:
    call input_update
    call player_update
    call video_draw
    jr .loop
