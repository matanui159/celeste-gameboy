include "reg.inc"
include "util.inc"

def MAP_WIDTH  equ 32
def MAP_HEIGHT equ 16
def MAP_SIZE   equ MAP_WIDTH * MAP_HEIGHT 

section "map_rom", rom0


; (addr: hl) => bc <addr: hl>
tile_get_pos::
    ld de, -map_tiles & $ffff
    add hl, de
    ; X
    MV8 d, [REG_SCX]
    ld a, l
    swap a
    rrca
    and a, $f8
    sub a, d
    add a, OAM_X_OFFSET
    ld b, a
    ; Y
    MV8 d, [REG_SCY]
    ld e, h
    ld a, l
    srl e
    rra
    srl e
    rra
    and a, $f8
    sub a, d
    add a, OAM_Y_OFFSET
    ld c, a
    ret


; (tile: a, addr: hl) => hl
tile_load::
    push bc
    ld [hl], a
    ; get the palette from the attributes
    ld b, high(GenAttrs)
    ld c, a
    ld a, [bc]
    and a, MAP_ATTR_PALETTE
    inc h
    inc h
    ld [hl+], a
    dec h
    dec h
    pop bc
    ret


; (id: a) => void
map_load::
    add a, high(GenMaps)
    ld b, a
    ld c, $00
    ld hl, map_tiles
    ; setup return address for `load` functions
    ld de, .return
    push de
    ld de, $10
.loop:

    ; handle the tile
    ld a, [bc]
    cp a, 1
    jp z, player_load

    jr .default
.return:
    ; reuse return address
    add sp, -2
    xor a, a
.default:
    call tile_load

    dec e
    jr nz, .cont
    ld e, $10
    add hl, de
.cont:
    inc c
    jr nz, .loop
    pop de
    ret


; () => void
map_init::
    ; setup scroll registers
    MV8 [REG_SCX], -16
    MV8 [REG_SCY], -8

    ; while the map is clear, use it to clear the bottom half of the map
    HDMA MEM_TILE_MAP0 + MAP_SIZE, map_tiles, MAP_SIZE
    MV8 [c], $01
    HDMA MEM_TILE_MAP0 + MAP_SIZE, map_attrs, MAP_SIZE
    MV0 [c]

    ; load the first map
    jp map_load


; () => void
map_draw::
    HDMA MEM_TILE_MAP0, map_tiles, MAP_SIZE
    ld c, low(REG_VBK)
    MV8 [c], $01
    HDMA MEM_TILE_MAP0, map_attrs, MAP_SIZE
    MV0 [c]
    ret


; (pos: bc) => hl <pos: bc>
tile_get_addr::
    ; X
    MV8 d, [REG_SCX]
    ld a, b
    sub a, OAM_X_OFFSET
    add a, d
    and a, $f8
    swap a
    rlca
    ld l, a
    ; Y
    MV8 d, [REG_SCY]
    ld a, c
    sub a, OAM_Y_OFFSET
    add a, d
    and a, $f8
    ld h, 0
    add a, a
    rl h
    add a, a
    rl h

    or a, l
    ld l, a
    ld de, map_tiles
    add hl, de
    ret


; (addr: hl) => a
tile_get_attr::
    ld d, high(GenAttrs)
    ld e, [hl]
    ld a, [de]
    ret


section fragment "VBlank", rom0
    call map_draw


section "map_wram", wram0, align[4]
map_tiles:: ds MAP_SIZE
map_attrs:: ds MAP_SIZE
