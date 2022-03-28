if !def(UTIL_INC)
def UTIL_INC equ 1
include "reg.inc"


; (dst: 8, src: 8) => void
macro LDA
    ld a, \2
    ld \1, a
endm


; (dst: 8) => void
macro LDZ
    xor a, a
    ld \1, a
endm


; (dst: 16, src: 16, size: n16) => void
macro HDMA
assert (\1) & $f == $0
assert (\2) & $f == $0
assert (\3) & $f == $0
assert (\3) > 0 && (\3) <= $800
    ld hl, REG_HDMA_HISRC
    LDA [hl+], high(\2)
    LDA [hl+], low(\2)
    LDA [hl+], high(\1)
    LDA [hl+], low(\1)
    LDA [hl+], ((\3) >> 4) - 1
endm


endc
