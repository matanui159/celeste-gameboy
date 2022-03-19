include "hardware.inc"
rsreset
def OBJ_CALLBACK rw 1
def OBJ_DATA     rw 1
def sizeof_OBJ   rb 0

section "object_rom", rom0


; () => void
clear_objects::
    ld hl, objects
    xor a, a
    ld b, OAM_COUNT
.loop:
    ld [hl+], a
    inc l
    ld [hl+], a
    inc l
    dec b
    jr nz, .loop
    ret


; (src_hi: a, wait: b, reg: c) => void
copy_oam_rom:
load "object_load", hram
copy_oam:
    ldh [c], a
.loop:
    dec b
    jr nz, .loop
    ret
endl    


; () => void
init_objects::
    call clear_objects
    ld hl, copy_oam
    ld bc, copy_oam_rom
    ld de, sizeof("object_load")
    jp memcpy


; (id: a, pos: bc, tile: d, attr: e, data: hl) => void <callback_ptr: hl>
save_object:
    push hl
    ld h, high(objects)
    add a, a
    add a, a
    ld l, a

    ; Y position
    ld a, c
    add a, $10
    ld [hl+], a
    
    ; X position
    ld a, b
    add a, $08
    ld [hl+], a

    ; tile & attributes
    ld a, d
    ld [hl+], a
    ld [hl], e

    ; data
    pop bc
    ld h, high(object_data)
    ld a, b
    ld [hl-], a
    ld a, c
    ld [hl-], a
    dec hl
    ret


; () => void
update_objects::
    ret


; () => void
copy_objects::
    ld a, high(objects)
    ld b, 40
    ld c, low(rDMA)
    jp copy_oam


; callback: (pos: bc, tile: d, attr: e, data: hl) => { pos: bc, tile: d, attr: e, data: hl }
; (pos: bc, tile: d, attr: e, data: hl, callback: stack) => a
alloc_object::
    ; We use the tile to detect if an object exists
    push hl
    ld hl, objects + 2
    push bc
    ld b, OAM_COUNT
.loop:
    ld a, [hl+]
    cp a, 0
    jr z, .alloc
    inc l
    inc l
    inc l
    dec b
    jr nz, .loop
    pop bc
    pop hl
    ret

.alloc:
    ld a, OAM_COUNT
    sub a, b
    pop bc
    pop hl
    push af
    call save_object

    ; Stack right now is tild_id, return, callback. We need the callback
    ld b, h
    ld c, l
    ld hl, sp+4
    ld a, [hl+]
    ld [bc], a
    inc bc
    ld a, [hl+]
    ld [bc], a
    pop af
    ret


; (id: a) => void
free_object::
    ; We have tp clear both the tile and the Y position (off the screen)
    ld h, high(objects)
    add a, a
    add a, a
    ld l, a
    xor a, a
    ld [hl+], a
    inc l
    ld [hl], a
    ret


section "object_oam", wram0, align[8]
objects: ds OAM_COUNT * sizeof_OAM_ATTRS

section "object_data", wram0, align[8]
object_data: ds OAM_COUNT * sizeof_OAM_ATTRS
