section "Fruit ROM", rom0


;; Removed any fruit-related object
FruitClear::
    ; Set the fruit type to NONE (0)
    xor a, a
    ldh [hFruitType], a
    ret


section "Fruit common HRAM", hram
hFruitType:: db
hFruitCollected:: db
