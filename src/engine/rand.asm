section "rand_timer", rom0[$0050]
    nop
    jp int_timer

section "rand_rom", rom0


; () => void
init_rand::
    ld hl, rand_state
    ld a, $ff
    ld [hl+], a
    ld [hl+], a
    ld a, $80
    ldh [REG_TMA], a
    ld a, $04
    ldh [REG_TAC], a
    ret


; () => a
rand::
    ld hl, rand_state
    ld a, [hl+]
    ld b, [hl]

    ; x ^= x << 7
    ld l, a
    ld h, b
    ld c, 0
    srl b
    rra
    rr c
    xor a, h
    ld b, a
    ; shift now for later, carry is 0 from xor
    rra
    ld h, a
    ld a, c
    xor a, l

    ; x ^= x >> 9
    xor a, h

    ; x ^= x << 8
    ld c, a
    xor a, b

    ld hl, rand_state + 1
    ld [hl-], a
    ld [hl], c
    swap a
    xor a, c
    ret


; () => void
int_timer:
    push af
    push bc
    push hl
    ; add more entropy to the randomiser
    call rand
    pop hl
    pop bc
    pop af
    reti


section "rand_wram", wram0
rand_state: dw
