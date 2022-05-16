section fragment "Bitmaps", romx, bank[1]
BitmapsEnd::


section fragment "VBlank", rom0
    pop hl
    pop bc
    ldh a, [hVideoFrames]
VBlankReturn::
    inc a
    ldh [hVideoFrames], a
    pop af
    reti
