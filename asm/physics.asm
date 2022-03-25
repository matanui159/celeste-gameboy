macro sub16
    ld a, low(\1)
    sub a, low(\2)
    ld low(\1), a
    ld a, high(\1)
    sbc a, high(\2)
    ld high(\1), a
endm

macro cp16
    ld a, low(\1)
    sub a, low(\2)
    ld a, high(\1)
    sbc a, high(\2)
endm

macro ret_le
    ld a, high(\1)
    xor a, high(\2)
    bit 7, a
    jr nz, .diffsign\@
    cp16 \2, \1
    ret nc
    jr .cont\@
.diffsign\@:
    bit 7, high(\1)
    ret nz
.cont\@:
endm

section "physics_rom", rom0


; (value: hl, target: bc, accel: de) => hl
accel::
    ; in the lua version this is called appr
    ; I think that stands for appreciate??
    ; check first if already equal
    ld a, h
    cp a, b
    jr nz, .notequal
    ld a, l
    cp a, c
    ret z
.notequal:
    ; try increasing
    add hl, de
    ret_le hl, bc
    ; try decreasing
    sub16 hl, de
    sub16 hl, de
    ret_le bc, hl
    ; set it to the target
    ld h, b
    ld l, c
    ret
