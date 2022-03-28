include "reg.inc"
include "util.inc"

def MAP_WIDTH  equ 32
def MAP_HEIGHT equ 16
def MAP_SIZE   equ MAP_WIDTH * MAP_HEIGHT 

section "map_rom", rom0


; (pos: l) => bc
tile_get_pos::
    ; X
    LDA d, [REG_SCX]
    ld a, l
    and a, $0f
    swap a
    rra
    sub a, d
    add a, OAM_X_OFFSET
    ld b, a
    ; Y
    LDA d, [REG_SCY]
    ld a, l
    and a, $f0
    rra
    sub a, d
    add a, OAM_Y_OFFSET
    ld c, a
    ret


; (pos: l) => hl
tile_get_addr::
    ld a, l
    and a, $0f
    ld b, a
    ; we have to multiply the Y nybble by 2
    xor a, a
    sla l
    adc high(map_tiles)
    ld h, a
    ld a, l
    and a, $e0
    or a, b
    ld l, a
    ret


; (tile: a, pos: l)
tile_load::
    ld c, a
    call tile_get_addr
    ld [hl], c

    ; get the palette from the attributes
    ld b, high(gen_attrs)
    ld a, [bc]
    and a, MAP_ATTR_PALETTE
    inc h
    inc h
    ld [hl], a
    ret


; (id: a) => void
map_load::
    add a, high(gen_maps)
    ld h, a
    ld l, $00
.loop:
    ld a, [hl]

    ; handle the tile
    push hl
    ; retup return address
    ld bc, .return
    push bc
    cp a, 1
    jp z, player_load
    ; goto default
    pop bc
    jr .default
.return:
    pop hl
    push hl
    xor a, a
.default:
    call tile_load
    pop hl

    inc l
    jr nz, .loop
    ret


; () => void <reg_vbk: c>
map_draw::
    HDMA MEM_TILE_MAP0, map_tiles, MAP_SIZE
    ld c, low(REG_VBK)
    LDA [c], $01
    HDMA MEM_TILE_MAP0, map_attrs, MAP_SIZE
    LDZ [c]
    ret


; () => void
map_init::
    ; setup scroll registers
    LDA [REG_SCX], -16
    LDA [REG_SCY], -8

    ; while the map is clear, use it to clear the bottom half of the map
    HDMA MEM_TILE_MAP0 + MAP_SIZE, map_tiles, MAP_SIZE
    LDA [c], $01
    HDMA MEM_TILE_MAP0 + MAP_SIZE, map_attrs, MAP_SIZE
    LDZ [c]

    ; load and draw the first map
    call map_load
    jp map_draw


section "map_wram", wram0, align[8]
map_tiles: ds MAP_SIZE
map_attrs: ds MAP_SIZE
