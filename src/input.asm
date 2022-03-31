include "reg.inc"
include "util.inc"

; (joyp: 8) => a
macro INPUT_HALF
    MV8 [c], \1
rept 4
    ld a, [c]
endr
    cpl
    and a, $0f
endm

section "input_rom", rom0


; () => void
input_update::
    ld c, low(REG_JOYP)
    INPUT_HALF JOYP_NO_ACT
    ld b, a
    INPUT_HALF JOYP_NO_DIR
    swap a
    or a, b
    ld [input], a
    ret


section "input_wram", wram0
input:: db
