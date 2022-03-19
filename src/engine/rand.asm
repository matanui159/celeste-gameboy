section "rand_rom", rom0


; () => void
init_rand::
    ld hl, rand_state
    ld a, $ff
    ld [hl+], a
    ld [hl+], a
    ret


; () => a
rand::
    ; ba = [rand_state]
    ld hl, rand_state
    ld a, [hl+]
    ld b, [hl]
    ; hl = ba
    ld l, a
    ld h, b
    ; ac = ba << 7 (8 - 1)
    ld c, 0
    srl b
    rra
    rr c
    ; ba = hl ^ ac
    xor a, h
    ld b, a
    ; _h = (hl ^ ac) >> 9 (8 + 1, used below)
    rra
    ld h, a
    ld a, c
    xor a, l
    ; ba ^= _h
    xor a, h
    ; bc = ba
    ld c, a
    ; ac = bc ^ (ba << 8) 
    xor a, b
    ; [rand_state] = ac
    ld hl, rand_state + 1
    ld [hl-], a
    ld [hl], c
    ; a = swap(a) ^ c
    swap a
    xor a, c
    ret


section "rand_wram", wram0
rand_state: dw
