section fragment "VBlank", rom0
    xor a, a
VBlankReturn::
    ld [hVideoState], a
    pop af
    reti
