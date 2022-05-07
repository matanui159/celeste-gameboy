include "../hardware.inc"

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
; TODO: maybe all this should be renamed to "room" to match the original code


;; Clears the update queue
ClearQueue:
    ld a, OP_RET
    ld [wUpdateQueue], a
    ret


;; A faster copy routine specifically for copying rows from WRAM to VRAM
;; @param hl: Destination address to copy to
;; @param bc: Source address to copy from
;; @effect hl: Destination end address
;; @saved bc
CopyMap:
    ld de, MAP_X_B
.loop:
    ; Copy over one row to VRAM
rept MAP_X_B
    ld a, [bc]
    inc c
    ld [hl+], a
endr
    ; The VRAM screen is double the size of the map
    add hl, de
    ; If the last increment ended with 0, we have rached the end of the map
    ; Surprisingly, 16-bit addition doesn't overwrite the Z flag
    jr nz, .loop
    ret


;; Perform a CGB-only HDMA from WRAM to VRAM
;; @param bc: Source address to copy from
;; @effect a: Zero
;; @saved bc
CopyMapDMA:
    ld hl, rHDMA1
    ; Source address high byte
    ld a, b
    ld [hl+], a
    ; Source address low byte
    ld a, c
    ld [hl+], a
    ; Destination address high byte
    ld a, high(_SCRN0)
    ld [hl+], a
    ; Destination address low byte, which is $00 for _SCRN0
    xor a, a
    ld [hl+], a
    ; (length / 16) - 1
    ; This starts the HDMA
    ld [hl], ((SCRN_VX_B * MAP_Y_B) / 16) - 1
    ret


;; @param a: Map ID
MapLoad::
    ldh [hMapIndex], a
    ; Copy the map to our buffer
    ld hl, wMapTiles
    add a, high(GenMaps)
    ld b, a
    ; Both the map tiles and the generated maps are page-aligned
    ld c, l
    ld de, MAP_X_B * MAP_Y_B
    call MemoryCopy

    ; Setup the return address for `load` functions
    ld bc, .loadReturn
    push bc

    ; Load all the different tiles if needed
    ; We do this in a seperate step from the initial copy so that tiles can
    ; modify other tiles during load
    ; HL is one page after `wMapTiles` due to the `MemoryCopy` effect. Due to
    ; the map being one page in size, we can stop looping when L becomes 0.
    dec h
.loadLoop:

    ; Handle the tile. All the `load` functions must not override `hl`
    ld a, [hl]
    cp a, 1
    jp z, PlayerLoad

.loadContinue:
    inc l
    jr nz, .loadLoop
    ; Remove the return address from the stack
    pop bc

    ; Clear the update queue since we're going to be updating the whole screen
    call ClearQueue

    ; Check which method to use for copying the map to VRAM
    ldh a, [hMainBoot]
    cp a, BOOTUP_A_CGB
    jr z, .cgbCopy

    ; On DMG, we disable LCD and copy over the map to VRAM naively
    call VideoWait
    xor a, a
    ldh [rLCDC], a
    ; Copy over the map while the LCD is disabled
    ld hl, _SCRN0
    ld bc, wMapTiles
    call CopyMap
    jr .copyEnd

.cgbCopy:

    ; On CGB we first copy to a point in memory that is similar to VRAM
    ; (double width) and then use HDMA to copy it to the real VRAM during
    ; V-blank without having to disable the screen.
    ; Copy over the map tiles
    ld hl, wCgbTiles
    ld bc, wMapTiles
    call CopyMap

    ; Get the palettes from the attributes. HL is already incremented to point
    ; to the next section, BC is still the same
    ; D is the high byte for GenAttrs, E is the width of the map
    ld de, GenAttrs | MAP_X_B
.attrLoop:
    ld a, [bc]
    inc c
    push de
    ld e, a
    ld a, [de]
    pop de
    and a, OAMF_PALMASK
    ld [hl+], a
    dec e
    jr nz, .attrLoop
    ; After each row we add the map width to the HL pointer
    ld de, MAP_X_B
    add hl, de
    ; Setup the high byte for GenAttrs again
    ld d, high(GenAttrs)
    ; Loop if we have not reached the end of the map
    ld a, c
    or a, a
    jr nz, .attrLoop

    ; Setup registers for HDMA
    ld bc, wCgbTiles
    ; Low byte is 1 for switching V-bank, high byte is for `wCgbAttrs`
    ld de, wCgbAttrs | 1
    ; Wait for V-blank
    call VideoWait
    ; Use DMA for the map tiles
    call CopyMapDMA
    ; Switch to VRAM bank 1
    ld a, e
    ldh [rVBK], a
    ; Use DMA for the map attributes, BC is the same from above
    ld b, d
    call CopyMapDMA
    ; Switch back to VRAM bank 0 using effect from above
    ldh [rVBK], a

.copyEnd:

    ; Enable LCD and return
    ; We still do this on CGB since if this is the first call, the LCD would
    ; already be disabled
    ld a, LCDCF_BGON | LCDCF_BG8000 | LCDCF_ON
    ldh [rLCDC], a
    ret

.loadReturn:
    ; The return address for the `load` functions. We move it here so we don't
    ; have to jump over it to escape the loop above.
    ; Reuse the return address for later `load` functions
    add sp, -2
    jr .loadContinue


;; Initializes the map rendering and update routines
MapInit::
    ; Clear the update queue so the first load doesn't do anything funky with
    ; memory
    call ClearQueue
    ; Clear out the tiles in screen 0
    ld hl, _SCRN0
    ld de, SCRN_VX_B * SCRN_VY_B
    call MemoryClear

    ; Check if we have to clear attributes and CGB buffers
    ldh a, [hMainBoot]
    cp a, BOOTUP_A_CGB
    jr nz, .clearEnd
    ; Clear out the CGB buffers
    ld hl, wCgbTiles
    ld de, SCRN_VX_B * MAP_Y_B * 2
    call MemoryClear
    ; Swap to VRAM bank 1 and clear out the attributes
    ld a, 1
    ldh [rVBK], a
    ld hl, _SCRN0
    ld de, SCRN_VX_B * SCRN_VY_B
    call MemoryClear
    ; Swap back to VRAM bank 0 using effect from MemoryClear
    ldh [rVBK], a
.clearEnd:

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


;; Finds the nearest tile to the provided position
;; @param bc: X and Y position
;; @returns %z: Set if a tile was found
;; @returns  l: Tile position
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
    ; If the X is >=128 (highest bit set) the point is off the map
    bit 7, a
    ret nz
    ; Shift right by 3
    add a, a
    swap a
    and a, $0f
    ld l, a

    ; Get the Y scroll position
    ldh a, [rSCY]
    ld d, a
    ; Y position (high nybble)
    ; Undo offsets
    ld a, c
    sub a, OAM_Y_OFS
    add a, d
    ; Check if the point is off the map
    bit 7, a
    ret nz
    ; Shift left by 1
    add a, a
    and a, $f0
    or a, l
    ld l, a
    ; Make sure %z is set
    xor a, a
    ret


;; Performs a collision with the tile closest to the provided position.
;; Collision callbacks will be invoked and any flags will be returned.
;; @param bc: X and Y position
;; @returns a: Tile flags
;; @saved bc
MapCollideTileAt::
    ; Find the tile and return if its off the map
    call MapFindTileAt
    ; We use LD instead or XOR so we don't overwrite the Z flag
    ld a, 0
    ret nz
    ; Get the tile ID
    ld h, high(wMapTiles)
    ld a, [hl]
    ; Setup the return address for collisions
    ld de, .return
    push de

    ; TODO: Handle collision callbacks

    pop de
.return:
    ; Get the attributes from the lookup table
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
    call ClearQueue


section "Map WRAM", wram0, align[8]
wMapTiles:: ds MAP_X_B * MAP_Y_B
wCgbTiles: ds SCRN_VX_B * MAP_Y_B
wCgbAttrs: ds SCRN_VX_B * MAP_Y_B
; 5 bytes required for `ld a, <value>; ld [<addr>], a` and 1 byte for `ret`
wUpdateQueue: ds MAP_UPDATES * 5 + 1


section "Map HRAM", hram
hMapIndex:: db
