def BLACK equ $0000
def DARK_BLUE equ $28c4
def DARK_PURPLE equ $28ad
def DARK_GREEN equ $25c0
def BROWN equ $1d31
def DARK_GREY equ $254b
def LIGHT_GREY equ $5273
def WHITE equ $635f
def RED equ $241f
def ORANGE equ $021f
def YELLOW equ $173f
def GREEN equ $1ee0
def BLUE equ $7e26
def LAVENDER equ $418d
def PINK equ $459f
def LIGHT_PEACH equ $469f

section "palette_rom", romx
celeste_bgp::
    ; ground & ice
    dw BLACK, DARK_GREY, BLUE, WHITE
    ; spikes
    dw BLACK, DARK_GREY, LIGHT_GREY, WHITE
    ; fall floors
    dw BLACK, DARK_BLUE, BROWN, ORANGE
    ; springs
    ; TODO: this could be merged with fall floors??
    dw BLACK, DARK_GREY, BROWN, ORANGE
.end::

celeste_obp::
    ; player
    dw BLACK, DARK_GREEN, LIGHT_PEACH, RED
.end::
