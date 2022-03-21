include "hardware.inc"

section "object_rom", rom0


; () => void
clear_objects::
    ld hl, object_oam
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
    ld hl, object_oam
    ld b, OAM_COUNT
.loop:
    ; we check the tile to see if it exists
    inc l
    inc l
    ld a, [hl+]
    cp a, $00
    jr nz, .update
.next:
    inc l
    dec b
    jr nz, .loop
    ret

.update:
    push bc
    push hl
    ; push the return address so the callback returns here
    ld bc, .return
    push bc
    ; load the data
    ld h, high(object_data)
    ld d, [hl]
    dec l
    ld e, [hl]
    dec l
    ; load the callback
    ld b, [hl]
    dec l
    ld c, [hl]
    ; push the callback so we can call it with a ret
    push bc
    ; push the data so we can pop it into hl later
    push de
    ; load the tile
    ld d, a
    ; load Y
    ld h, high(object_oam)
    ld a, [hl+]
    sub a, OAM_Y_OFS
    ld c, a
    ; load X
    ld a, [hl+]
    sub a, OAM_X_OFS
    ld b, a
    ; skip the tile
    inc l
    ; load the attributes
    ld e, [hl]    

    ; call the callback
    pop hl
    ret

.return:
    ; push the data and get the original hl
    push hl
    ld hl, sp+2
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ; save the attributes
    ld a, e
    ld [hl-], a
    ; save the tile
    ld a, d
    ld [hl-], a
    ; save X
    ld a, b
    add a, OAM_X_OFS
    ld [hl-], a
    ; if tile=0, save Y=0 so it is off the screen
    xor a, a
    cp a, d
    jr z, .save_y
    ; otherwise, save Y with offset
    ld a, c
    add a, OAM_Y_OFS
.save_y:
    ld [hl+], a
    ; save the data
    pop bc
    ld h, high(object_data)
    inc l
    ld a, c
    ld [hl+], a
    ld [hl], b

    pop hl
    pop bc
    jr .next


; () => void
draw_objects::
    ld a, high(object_oam)
    ld b, 40
    ld c, low(rDMA)
    jp copy_oam


; callback: (pos: bc, tile: d, attr: e, data: hl) => { pos: bc, tile: d, attr: e, data: hl }
; (pos: bc, tile: d, attr: e, data: hl, callback: stack) => void
alloc_object::
    push hl
    push bc
    ld hl, object_oam
    ld b, OAM_COUNT
.loop:
    ; we check the tile to see if it exists
    inc l
    inc l
    ld a, [hl+]
    cp a, $00
    jr z, .alloc
    inc l
    dec b
    jr nz, .loop
    pop bc
    pop hl
    ret

.alloc:
    ld bc, .return
    push bc
    ld b, $01
    push bc
    push hl
    ld hl, sp+6
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp update_objects.return

.return:
    add sp, 4
    ld a, l
    sub a, 4
    ld hl, sp+2
    ld c, [hl]
    inc l
    ld b, [hl]
    ld h, high(object_data)
    ld l, a
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret


section "object_oam", wram0, align[8]
object_oam: ds OAM_COUNT * sizeof_OAM_ATTRS

section "object_data", wram0, align[8]
object_data: ds OAM_COUNT * sizeof_OAM_ATTRS
