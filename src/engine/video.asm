section "video_vblank", rom0[$0040]
    nop
    jp int_vblank

section "video_rom", rom0


copy_oam_rom:
load "video_load", hram
; (src_hi: a, wait: b, reg: c) => void
copy_oam:
    ldh [c], a
.loop:
    dec b
    jr nz, .loop
    ret
.end:
endl


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
    ld hl, REG_LCDC
    bit 7, [hl]
    jr z, .disabled
    ; if not wait for next vblank
    ld b, l
    ld l, low(REG_IE)
    ld [hl], $01
    ld l, low(REG_IF)
    res 0, [hl]
    halt
    ld l, b
    res 7, [hl]

.disabled:
    xor a, a
    ldh [video_state], a

    ld hl, video_oam
    ld de, video_oam.end - video_oam
    call memset

    ld a, $48
    ld hl, VRAM_TMAP
    ld de, $400
    call memset
    xor a, a

    ld b, celeste_bgp.end - celeste_bgp
    ld c, low(REG_BGPI)
    ld hl, celeste_bgp
    call copy_palette

    xor a, a
    ld b, celeste_bgp.end - celeste_bgp
    ld hl, celeste_obp
    call copy_palette

    ld hl, VRAM_TDAT
    ld bc, celeste_sprites
    ld de, celeste_sprites.end - celeste_sprites
    call memcpy

    ld hl, copy_oam
    ld bc, copy_oam_rom
    ld de, copy_oam.end - copy_oam
    call memcpy

    ld a, $93
    ldh [REG_LCDC], a
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
    ld a, high(video_oam)
    ld b, $40
    ld c, low(REG_DMA)
    call copy_oam
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


section "video_wram", wram0, align[8]
video_oam:
    ds $a0
.end:

section "video_hram", hram
; bit 0: a singular frame has passed so the next frame will update and draw (to
;        limit to 30Hz)
; bit 1: updating is finished and the non-interrupt code is waiting for the next
;        draw to finish
; vblank sets bit 0 but will not update anything until both bit 0 and bit 1 are
; set
video_state: db
