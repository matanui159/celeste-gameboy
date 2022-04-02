section "rand_rom", rom0


; () => void
rand_init::
    ; [rand_state] = $ffff
    ld a, $ff
    ld hl, rand_state
    ld [hl+], a
    ld [hl+], a
    ret


; () => a
rand::
    ld hl, rand_state
    ; ba = [hl+]
    ld a, [hl+]
    ld b, [hl]
    ; de = ba
    ld e, a
    ld d, b
    ; ac = ba << 7 (8 - 1)
    srl b
    rra
    ld c, $00
    rr c
    ; ba = ac ^ de
    xor a, d
    ld b, a
    ; 0d = ba >> 9 (8 + 1)
    rra
    ld d, a
    ld a, c
    xor a, e
    ; ba ^= 0d
    xor a, d
    ; bc = ba
    ld c, a
    ; ac = bc ^ (ba << 8)
    xor a, b
    ; [hl-] = ac
    ld [hl-], a
    ld [hl], c
    ; a ^= swap(c)
    swap c
    xor a, c
    ret


section "rand_wram", wram0
rand_state: dw
