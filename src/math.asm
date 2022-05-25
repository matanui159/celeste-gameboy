section "Math ROM", rom0


;; Gets the sin value of a specific angle
;; @param a: The angle in the range from 0->128
;; @returns a: The sin of A in the range of -128->127
MathSin::
    ; Save A into B so we can check bits later
    ld b, a
    ; The sine wave flips between "facing" left and right which we can find with
    ; the 5th bit
    bit 5, b
    jr z, .facingEnd
    ; Flip it the other way
    cpl
.facingEnd:
    ; Read out the sine value
    ld h, high(SinTable)
    and a, $1f
    ld l, a
    ld a, [hl]
    ; Check if the value should be negative by checking the 6th bit
    bit 6, b
    ; If not, we're done
    ret z
    ; If yes, negate it
    cpl
    ret


;; Performs modulo 6 on an 8-bit value
;; @param a: Input value
;; @param a: Modulo 6 of the input
MathModuloSix::
    ; Modulo values for each bit are:
    ;  0:  1
    ;  1:  2
    ;  2: -2
    ;  3:  2
    ;  4: -2
    ;  5:  2
    ;  6: -2
    ;  7:  2
    ; We can leave the lower 2 bits as is
    ld b, a
    and a, $03
    srl b
    srl b
    ld c, a
    ; Decrement for each even bit and increment for each odd bit
    xor a, a
    ; Save zero into D so we can use it in ADC later
    ld d, a
rept 3
    srl b
    sbc a, d
    srl b
    adc a, d
endr
    ; Times by 2 (since each inc/dec is +/-2) and add the low 2 bits
    add a, a
    add a, c
    ; Handle negative values
    bit 7, a
    jr nz, .neg
    ; If the value is <6 we can return now
    cp a, 6
    ret c
    ; Otherwise, subtract 6
    sub a, 6
    ret
.neg:
    ; If the value is negative, return 6+A
    add a, 6
    ret


section "Math ROMX", romx, bank[1], align[8]

SinTable:
def _angle = 0.0
rept 32
    db sin(_angle) >> 9
def _angle = _angle + 512.0
endr
