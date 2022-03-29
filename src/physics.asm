include "util.inc"

section "physics_rom", rom0


; (value: hl, target: bc, accel: de) => void
accel::
    ; This is called `appr` in the original source code
    ; Likely short for appreciate
    JRL16 hl, bc, .less
    SUB16 hl, de
    JRL16 hl, bc, .equal
.return:
    ret
.less:
    add hl, de
    JRL16 hl, bc, .return
.equal:
    LD16 hl, bc
    ret
