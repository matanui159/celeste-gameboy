include "../hardware.inc"

section "Input ROM", rom0


;; Updates the input variables in HRAM
InputUpdate::
    ld c, low(rP1)
    ; Get the DPAD buttons
    ld a, P1F_GET_DPAD
    ldh [c], a
rept 4
    ldh a, [c]
endr
    ; Invert and get the lower half, save in B
    cpl
    and a, $0f
    ld b, a
    ; Get the action buttons
    ld a, P1F_GET_BTN
    ldh [c], a
rept 4
    ldh a, [c]
endr
    ; Invert and get the lower half, merge with B
    cpl
    and a, $0f
    swap a
    or a, b

    ; Save into HRAM and compare against the previous frame
    ld b, a
    ldh a, [hInput]
    ; Is pressed now AND NOT pressed last frame
    cpl
    and a, b
    ldh [hInputNext], a
    ld a, b
    ldh [hInput], a
    ret


section "Input HRAM", hram
hInput:: db
hInputNext:: db
