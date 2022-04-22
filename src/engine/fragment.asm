section fragment "VBlank", rom0
    pop hl
    ldh a, [hVideoFrames]
VBlankReturn::
    inc a
    ldh [hVideoFrames], a
    pop af
    reti
