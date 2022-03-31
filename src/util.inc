if !def(UTIL_INC)
def UTIL_INC equ 1
include "reg.inc"


; (dst: 8, src: 8) => void
macro MV8
    ld a, \2
    ld \1, a
endm


; (dst: 8) => void
macro MV0
    xor a, a
    ld \1, a
endm


; (acc: r8, label: 16) => void
macro JRN8
    bit 7, \1
    jr nz, \2
endm


; (acc: r8, label: 16) => void
macro JRP8
    bit 7, \1
    jr z, \2
endm


; (dst: r16, src: r16) => void
macro MV16
    ld low(\1), low(\2)
    ld high(\1), high(\2)
endm


; (dst: r16, addr: n16) => void
macro LD16
    MV8 low(\1), [\2]
    MV8 high(\1), [(\2) + 1]
endm


; (addr: n16, src: 16) => void
macro ST16
    MV8 [\1], low(\2)
    MV8 [(\1) + 1], high(\2)
endm


; (acc: r16, val: 16) => void
macro SUB16
    ld a, low(\1)
    sub a, low(\2)
    ld low(\1), a
    ld a, high(\1)
    sbc a, high(\2)
    ld high(\1), a
endm


; (acc: r16) => void
macro NEG16
    xor a, a
    sub a, low(\1)
    ld low(\1), a
    ld a, 0
    sbc a, high(\1)
    ld high(\1), a
endm


; (acc: r16) => void
macro ABS16
    JRP8 high(\1), .cont\@
    NEG16 \1
.cont\@:
endm


; (acc: r16, val: 16) => void
macro CP16
    ld a, low(\1)
    sub a, low(\2)
    ld a, high(\1)
    sbc a, high(\2)
endm


; (acc: r16, val: 16, label: 16) => void
macro JRL16
    ld a, high(\1)
    xor a, high(\2)
    bit 7, a
    jr nz, .diffsign\@
    CP16 \1, \2
    jr c, \3
    jr .cont\@
.diffsign\@:
    bit 7, high(\1)
    jr nz, \3
.cont\@:
endm


; (dst: 16, src: 16, size: n16) => void
macro HDMA
assert (\1) & $f == $0
assert (\2) & $f == $0
assert (\3) & $f == $0
assert (\3) > 0 && (\3) <= $800
    ld hl, REG_HDMA_HISRC
    MV8 [hl+], high(\2)
    MV8 [hl+], low(\2)
    MV8 [hl+], high(\1)
    MV8 [hl+], low(\1)
    MV8 [hl+], ((\3) >> 4) - 1
endm


endc
