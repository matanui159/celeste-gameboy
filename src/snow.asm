include "reg.inc"
include "util.inc"

section "snow_stat", rom0[$0048]
    jp snow_stat

section "snow_rom", rom0


; () => void
snow_init::
    ld hl, snow_spd
.loop:
    ; generate starting position
    push hl
    call rand
    pop hl
    dec h
    ld [hl], a
    ; generate speed
    push hl
    call rand
    and a, $03
    add a, 2
    pop hl
    inc h
    ld [hl+], a

    ld a, l
    cp a, OAM_Y_OFFSET + LCDC_HEIGHT
    jr nz, .loop

    ld hl, object_snow + OAM_TILE
    MV8 [hl+], $80
    MV8 [hl+], 1
    MV8 [REG_STAT], STAT_INT_HBLANK
    ; setup the HRAM buffer now so we don't modify random values
    ld a, OAM_Y_OFFSET
    ldh [snow_y], a
    ret


; () => void
snow_stat:
    ; This code is a bit weird because we first update the next row from the
    ; HRAM buffer, followed by updating the HRAM buffer for two rows ahead
    push af
    ldh a, [snow_x]
    ld [MEM_OAM + OAM_X], a
    ldh a, [snow_y]
    ld [MEM_OAM + OAM_Y], a
    cp a, OAM_Y_OFFSET
    jr z, snow_draw.return ; finish updating after v-blank

snow_draw::
    inc a
    cp a, OAM_Y_OFFSET + LCDC_HEIGHT
    jr nz, .update
    ld a, OAM_Y_OFFSET

.update:
    push hl
    ldh [snow_y], a
    ld l, a
    ld h, high(snow_pos)
    ld a, [hl]
    inc h
    sub a, [hl]
    dec h
    ld [hl], a
    ldh [snow_x], a
    pop hl
.return:
    pop af
    reti


; these are specifically placed so that they're have the correct alignments,
; offsets and are one page away from each other, while still allowing memory
; to be allocated in between
section "snow_pos", wram0[$c010]
snow_pos: ds LCDC_HEIGHT
section "snow_spd", wram0[$c110]
snow_spd: ds LCDC_HEIGHT

section "snow_hram", hram
snow_x: db
snow_y: db
