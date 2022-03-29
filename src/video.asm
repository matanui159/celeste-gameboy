include "reg.inc"
include "util.inc"

section "video_vblank", rom0[$0040]
    nop
    jp video_vblank

section "video_rom", rom0


; (reg: c, dst: a, src: hl, size: b) => void <next_reg: c>
video_palcpy::
    ld [c], a
    inc c
.loop:
    LDA [c], [hl+]
    dec b
    jr nz, .loop
    inc c
    ret


; () => void
video_init::
    ld c, low (REG_LCDC)
    ld a, [c]
    bit 7, a ; LCDC_ON
    jr z, .off
    LDA [REG_IE], INT_VBLANK
    LDZ [REG_IF]
    halt
    ld [c], a
.off:

    LDZ [video_state]
    HDMA MEM_TILE_DATA0, gen_tiles, gen_tiles.end - gen_tiles

    ld c, low(REG_BGPI)
    ld a, $00 | PI_INC
    ld hl, gen_bg_palettes
    ld b, gen_bg_palettes.end - gen_bg_palettes
    call video_palcpy

    ld a, $00 | PI_INC
    ld hl, gen_obj_palettes
    ld b, gen_obj_palettes.end - gen_obj_palettes
    jp video_palcpy


; () => void
video_draw::
    ; TODO: wait for second v-blank before updating so input is more up-to-date
    ld hl, video_state
    set 1, [hl]
.loop:
    halt
    ld a, [video_state]
    or a, a
    jr nz, .loop
    ret


; () => void
video_vblank:
    push af
    ld a, [video_state]
    cp a, $03
    set 0, a
    jr nz, .return

    ; we are in `video_draw` so we do not have to worry about saving registers
    call objects_draw
    call map_draw

    xor a, a
.return:
    ld [video_state], a
    pop af
    reti


section "video_wram", wram0
; bit 0: a singular frame has passed so the next frame will update and draw (to
;        limit to 30Hz)
; bit 1: updating is finished and the non-interrupt code is waiting for the next
;        draw to finish
; vblank sets bit 0 but will not update anything until both bit 0 and bit 1 are
; set
video_state: db
