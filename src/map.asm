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


;; Sets up the tile and the matching attributes from GenAttrs
;; @param a: Tile ID
;; @param l: Tile position
;; @saved hl
TileLoad:
    ld b, high(wMapTiles)
    ld c, l
    ld [bc], a
    ; Get the palette from the attributes
    ld d, high(GenAttrs)
    ld e, a
    ld a, [de]
    and a, OAMF_PALMASK
    ; Write the palette to wMapAttrs
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

    ; Clear the update queue since it's now out of date
    ld a, OP_RET
    ld [wUpdateQueue], a

    ; Disable LCD and copy over the map to VRAM
    call VideoDisable
    ld hl, _SCRN0
    ld bc, wMapTiles
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

    ; Restore the VRAM bank, enable LCD and return, register A is already zero
    ; from above
    ldh [rVBK], a
    ld a, LCDCF_BGON | LCDCF_OBJON | LCDCF_BG8000 | LCDCF_ON
    ldh [rLCDC], a
    ret


;; Initializes the map rendering and update routines
MapInit::
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
    ld a, 2
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


;; Finds the nearest tile to the provided position
;; @param bc: X and Y position
;; @returns l: Tile position
;; @saved bc
MapFindTileAt::
    ; Get the X scroll position
    ldh a, [rSCX]
    ld d, a
    ; X position (low nybble)
    ; Undo scroll and OAM offsets
    ld a, b
    sub a, OAM_X_OFS
    add a, d
    ; Shift right by 3
    add a, a
    swap a
    and a, $0f
    ld l, a
.capX:

    ; Get the Y scroll position
    ldh a, [rSCY]
    ld d, a
    ; Y position (high nybble)
    ; Undo offsets
    ld a, c
    sub a, OAM_Y_OFS
    add a, d
    ; Shift left by 1
    add a, a
    and a, $f0
.capY:
    or a, l
    ld l, a
    ret


;; Gets the attributes of a tile
;; @param l: Tile position
;; @returns a: Attributes
;; @saved l
MapTileAttributes::
    ; Get the tile ID
    ld h, high(wMapTiles)
    ld a, [hl]
    ; Get the original attributes from the lookup table
    ld d, high(GenAttrs)
    ld e, a
    ld a, [de]
    ret


;; Updates a tile in the map
;; @param a: Tile ID
;; @param l: Tile position
MapTileUpdate::
    ld h, high(wMapTiles)
    ld [hl], a
    ; Save A for later
    push af

    ; Figure out the address in VRAM
    ; The virtual screen width is twice that of the map so we have to multiply
    ; Y by 2 (adding it an extra time)
    ld h, high(_SCRN0)
    ld b, 0
    ld a, l
    and a, $f0
    ld c, a
    add hl, bc
    ld b, h
    ld c, l

    ; Find the end of the update queue (RET)
    ; We subtract 5 so that the first iteration can add 5
    ld hl, wUpdateQueue - 5
    ld de, 5
    ld a, OP_RET
.findLoop:
    ; Each copy takes 5 bytes so we can skip over 5 bytes at a time
    add hl, de
    cp a, [hl]
    jr nz, .findLoop

    ; Insert code to update it in VRAM during the next V-blank
    ; ld a, <Tile ID>
    ld a, OP_LD_A_D8
    ld [hl+], a
    pop af
    ld [hl+], a
    ; ld [<VRAM address>], a
    ld a, OP_LD_A16_A
    ld [hl+], a
    ; Low byte first (little-endian)
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ; ret
    ld [hl], OP_RET
    ret


section fragment "VBlank", rom0
VBlankMap:
    call wUpdateQueue
    ; Clear the queue
    ld a, OP_RET
    ld [wUpdateQueue], a


section "Map WRAM", wram0, align[8]
wMapTiles:: ds MAP_X_B * MAP_Y_B
wMapAttrs:: ds MAP_X_B * MAP_Y_B
; 5 bytes required for `ld a, <value>; ld [<addr>], a` and 1 byte for `ret`
wUpdateQueue: ds MAP_UPDATES * 5 + 1
