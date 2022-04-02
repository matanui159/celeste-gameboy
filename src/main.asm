include "reg.inc"
include "util.inc"

section "header_rom", rom0[$0100]
    jp main
    ds $4d

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

    call rand_init
    call video_init
    call map_init
    call objects_init
    call snow_init

    MV8 [REG_LCDC], LCDC_BG_DATA0 | LCDC_OBJ_ON | LCDC_ON
    MV8 [REG_IE], INT_VBLANK | INT_STAT
    MV0 [REG_IF]
    ei

.loop:
    ; add more entropy
    call rand

    call input_update
    call player_update
    call video_draw
    jr .loop
