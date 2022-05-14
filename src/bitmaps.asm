section fragment "Bitmaps", romx, bank[1]
; Most of the tiles are generated from gen_tiles.c and gen_text.c
; These only include a few 1bpp tiles
Bitmaps::
    ; The following squares are used for death animations
    ; 1x1 square
    db %00000000
    db %00000000
    db %00000000
    db %00010000
    db %00000000
    db %00000000
    db %00000000
    db %00000000

    ; 2x2 square
    db %00000000
    db %00000000
    db %00000000
    db %00011000
    db %00011000
    db %00000000
    db %00000000
    db %00000000

    ; 3x3 square
    db %00000000
    db %00000000
    db %00111000
    db %00111000
    db %00111000
    db %00000000
    db %00000000
    db %00000000

    ; 4x4 square
    db %00000000
    db %00000000
    db %00111100
    db %00111100
    db %00111100
    db %00111100
    db %00000000
    db %00000000
