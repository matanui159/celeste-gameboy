section fragment "VBlank", rom0
    pop bc
    ldh a, [hVideoFrames]
VBlankReturn::
    inc a
    ldh [hVideoFrames], a
    pop af
    reti
