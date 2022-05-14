section fragment "Bitmaps", romx, bank[1]
BitmapsEnd::


section fragment "VBlank", rom0
    pop hl
    ldh a, [hVideoFrames]
VBlankReturn::
    inc a
    ldh [hVideoFrames], a
    pop af
    reti
