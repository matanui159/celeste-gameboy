include "hardware.inc"

section "video_vblank", rom0[$0040]
    nop
    jp int_vblank

section "video_rom", rom0


; (dst: a, size: b, reg: c, src: hl) => void <next_reg: c>
copy_palette:
    set 7, a
    ldh [c], a
    inc c
    ; we copy two bytes at a time so half the size
    srl b
.loop:
    ld a, [hl+]
    ldh [c], a
    ld a, [hl+]
    ldh [c], a
    dec b
    jr nz, .loop
    inc c
    ret


; () => void
init_video::
    ; check if the LCD is disabled
    ld hl, rLCDC
    bit LCDCB_ON, [hl]
    jr z, .disabled
    ; if not wait for next vblank
    ld a, IEF_VBLANK
    ldh [rIE], a
    xor a, a
    ldh [rIF], a
    halt
    res LCDCB_ON, [hl]

.disabled:
    xor a, a
    ldh [video_state], a

    ld hl, _SCRN0
    ld de, _SCRN1 - _SCRN0
    call memset

    ld b, celeste_bgp.end - celeste_bgp
    ld c, low(rBCPS)
    ld hl, celeste_bgp
    call copy_palette

    xor a, a
    ld b, celeste_obp.end - celeste_obp
    ld hl, celeste_obp
    call copy_palette

    ld hl, _VRAM
    ld bc, startof("game_cgb_tiles")
    ld de, sizeof("game_cgb_tiles")
    call memcpy

    xor a, a
    call load_map
    call show_map

    ld a, LCDCF_BGON | LCDCF_BG8000 | LCDCF_ON
    ldh [rLCDC], a
    ret


; () => void
int_vblank:
    push af
    push bc
    ld c, low(video_state)
    ldh a, [c]
    cp a, 3
    set 0, a
    jr nz, .return
    ; ld a, high(celeste_oam)
    ; ld b, $40
    ; ld c, low(REG_DMA)
    ; call copy_oam
    ld c, low(video_state)
    xor a, a
.return:
    ldh [c], a
    pop bc
    pop af
    reti


; () => void
draw_video::
    ld hl, video_state
    set 1, [hl]
.wait:
    halt
    bit 1, [hl]
    jr nz, .wait
    ret


section "video_hram", hram
; bit 0: a singular frame has passed so the next frame will update and draw (to
;        limit to 30Hz)
; bit 1: updating is finished and the non-interrupt code is waiting for the next
;        draw to finish
; vblank sets bit 0 but will not update anything until both bit 0 and bit 1 are
; set
video_state: db
