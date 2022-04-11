include "hardware.inc"

; The width and height of the map in bytes, to match the SCRN_*_B constants
def MAP_X_B equ 16
def MAP_Y_B equ 16

; Arbitrary limit of updates per frame, matches the size of `wObjects`
def MAP_UPDATES equ 26

; Constants for some opcodes
def OP_LD_A_D8  equ $3e
def OP_LD_A16_A equ $ea
def OP_RET      equ $c9

section "Map ROM", rom0


;; Clears the update queue
MapUpdate::
    ld a, OP_RET
    ld [wUpdateQueue], a
    ret


;; Sets up the tile and the matching attributes from GenAttrs
;; @param a: Tile ID
;; @param l: Tile position
;; @saved hl
TileLoad:
    ld b, high(wTiles)
    ld c, l
    ld [bc], a
    ; Get the palette from the attributes
    ld d, high(GenAttrs)
    ld e, a
    ld a, [de]
    and a, OAMF_PALMASK
    ; Write the palette to wAttrs
    inc b
    ld [bc], a
    ret


;; @param a: Map ID
MapLoad::
    ; Generate the map address before A gets overwritten. Each map is
    ; page-aligned
    add a, high(GenMaps)
    ld h, a
    ld l, 0

    ; Setup the return address for `load` functions
    ld bc, .loadReturn
    push bc

    ; Iterate over the map. Since each map is exactly 1 page, we can end when
    ; L becomes 0 again.
.loadLoop:

    ; Handle the tile. All the `load` functions must not override `hl`
    ld a, [hl]
    cp a, 1
    jp z, PlayerLoad
    jr .defaultLoad

.loadReturn:
    ; Reuse the return address for later `load` functions
    add sp, -2
    ; Load tile-ID 0 in this index
    xor a, a
.defaultLoad:
    call TileLoad

    inc l
    jr nz, .loadLoop
    pop bc

    ; Clear the update queue since they're now out of date
    call MapUpdate

    ; Disable LCD and copy over the map to VRAM
    call VideoDisable
    ld hl, _SCRN0
    ld bc, wTiles
    ld de, MAP_X_B
.tileCopyLoop:
    ; Copy over a row of tiles
    call MemoryCopy
    ; The VRAM screen with is double that of the map, so we increment it further
    ; here before copying more tiles
    ld de, MAP_Y_B
    add hl, de
    ; Check if C is back to 0
    ld a, c
    or a, a
    jr nz, .tileCopyLoop

    ; Copy over the attributes in a similar fashion, using VRAM bank 1
    ld a, 1
    ldh [rVBK], a
    ld hl, _SCRN0
    ; We don't have to setup BC because it's already incremented to the next
    ; address
    ld de, MAP_X_B
.attrCopyLoop:
    ; Copy over a row of attributes
    call MemoryCopy
    ; Increment the screen address
    ld de, MAP_Y_B
    add hl, de
    ; Check C and repeat
    ld a, c
    or a, a
    jr nz, .attrCopyLoop

    ; Restor the VRAM bank, enable LCD and return, register A is already zero
    ; from above
    ldh [rVBK], a
    ld a, LCDCF_BGON | LCDCF_OBJON | LCDCF_BG8000 | LCDCF_ON
    ldh [rLCDC], a
    ret


;; Initializes the map rendering and update routines
MapInit::
    ; COMPATIBILITY: call the old init function
    ; call map_init

    ; Clear out the tiles in screen 0
    ld hl, _SCRN0
    ld de, SCRN_VX_B * SCRN_VY_B
    call MemoryClear
    ; Swap to VRAM bank 1 and clear out the attributes
    ld a, 1
    ldh [rVBK], a
    ld hl, _SCRN0
    ld de, SCRN_VX_B * SCRN_VY_B
    call MemoryClear
    ; Swap back to VRAM bank 0 using effect from MemoryClear
    ldh [rVBK], a

    ; Setup the scroll registers
    ld a, -16
    ldh [rSCX], a
    ld a, -8
    ldh [rSCY], a

    ; Load the first map
    xor a, a
    jp MapLoad


;; Gets the X, Y position from the tile position
;; @param l: Tile position
;; @returns bc: X and Y position
;; @saved hl
MapTilePosition::
    ; Get the X scroll position
    ldh a, [rSCX]
    ld b, a
    ; X position
    ld a, l
    and a, $0f
    ; Multiply it by 8: shift left 4, shift right 1
    swap a
    ; SWAP always sets carry to 0
    rra
    ; Apply scroll and OAM offsets
    sub a, b
    add a, OAM_X_OFS
    ld b, a

    ; Get the Y scroll position
    ldh a, [rSCY]
    ld c, a
    ; Y position
    ld a, l
    and a, $f0
    ; Multiply by 8, except it is already swapped
    ; AND always sets carry to 0
    rra
    ; Apply offsets
    sub a, c
    add a, OAM_Y_OFS
    ld c, a
    ret


section fragment "VBlank", rom0
VBlankMap:
    call wUpdateQueue


section "Map WRAM", wram0, align[8]
wTiles: ds MAP_X_B * MAP_Y_B
wAttrs: ds MAP_X_B * MAP_Y_B
; 5 bytes required for `ld a, <value>; ld [<addr>], a` and 1 byte for `ret`
wUpdateQueue:: ds MAP_UPDATES * 5 + 1


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


; section fragment "VBlank", rom0
; VBlankMap:
;     call map_draw


section "map_wram", wram0, align[4]
def map_tiles equ $c000
def map_attrs equ $c400
