include "../hardware.inc"

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


; () => void
update_objects::
    ld hl, objects
    ld b, OAM_COUNT
    ld c, $00
.loop:
    ; we check the tile to see if it exists
    inc l
    inc l
    ld a, [hl+]
    cp a, c
    jr nz, .update
    inc l
.next:
    dec b
    jr nz, .loop
    ret

.update:
    push bc
    ; get the attributes
    ld e, [hl]
    dec l
    ; get the tile
    ld d, a
    dec l
    ; get X
    ld a, [hl-]
    sub a, OAM_X_OFS
    ld b, a
    ; get Y
    ld a, [hl]
    sub a, OAM_Y_OFS
    ld c, a

    ; call update
    push hl
    ld h, high(startof("game_callbacks"))
    ld l, d
    ld a, [hl]
    add a, a
    add a, low(update_callbacks)
    ld l, a
    ld a, $00
    adc a, high(update_callbacks)
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    rst $00 ; call hl

    pop hl
.set_obj:
    ; if tile=0, set Y=0
    xor a, a
    cp a, d
    jr z, .set_y
    ; otherwise, set Y with offset
    ld a, c
    add a, OAM_Y_OFS
.set_y:
    ld [hl+], a
    ; set X
    ld a, b
    add a, OAM_X_OFS
    ld [hl+], a
    ; set the tile
    ld a, d
    ld [hl+], a
    ; set the attributes
    ld a, e
    ld [hl+], a

    pop bc
    jr .next


; () => void
draw_objects::
    ld a, high(objects)
    ld b, 40
    ld c, low(rDMA)
    jp copy_oam


; (pos: bc, tile: d, attr: e) => void
alloc_object::
    push bc
    ld hl, objects
    ld b, OAM_COUNT
    ld c, $00
.loop:
    ; we check the tile to see if it exists
    inc l
    inc l
    ld a, [hl+]
    cp a, c
    jr z, .alloc
    inc l
    dec b
    jr nz, .loop
    ret

.alloc:
    pop bc
    ; we reuse some code from update_objects
    ; shift hl down to match
    dec l
    dec l
    dec l
    ; this will be popped as bc making the loop exit immediately
    inc a
    push af
    jp update_objects.set_obj


section "object_wram", wram0, align[8]
objects: ds OAM_COUNT * sizeof_OAM_ATTRS
