include "../hardware.inc"

macro ld_input
    ld a, \1
    ldh [c], a
rept 4
    ldh a, [c]
endr
    cpl
    and a, $0f
endm

section "input_rom", rom0


; () => void
init_input::
    xor a, a
    ldh [prev_input], a
    ret


; () => void
update_input::
    ldh a, [prev_input]
    cpl
    ld d, a
    ld c, rP1
    ld_input P1F_GET_DPAD
    ld b, a
    ld_input P1F_GET_BTN
    swap a
    or a, b
    ldh [input], a
    ldh [prev_input], a
    and a, d
    ldh [next_input], a
    ret


section "input_hram", hram
prev_input: db
input:: db
next_input:: db
