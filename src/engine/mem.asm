section "mem_rom", rom0


; (dst: hl, src: bc, size: de) => void
memcpy::
    push de
    inc d
    jr .fast_start
.fast:
    ld e, $40
.fast_loop:
rept 4
    ld a, [bc]
    inc bc
    ld [hl+], a
endr
    dec e
    jr nz, .fast_loop
.fast_start:
    dec d
    jr nz, .fast
    pop de

    inc e
    jr .slow_start
.slow_loop:
    ld a, [bc]
    inc bc
    ld [hl+], a
.slow_start:
    dec e
    jr nz, .slow_loop
    ret


; (dst: hl, byte: a, size: de) => void
memset::
    inc d
    jr .fast_start
.fast:
    ld b, $20
.fast_loop:
rept 8
    ld [hl+], a
endr
    dec b
    jr nz, .fast_loop
.fast_start:
    dec d
    jr nz, .fast

    inc e
    jr .slow_start
.slow_loop:
    ld [hl+], a
.slow_start:
    dec e
    jr nz, .slow_loop
    ret
