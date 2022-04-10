section "Memory ROM", rom0


;; @param hl: Destination address
;; @param bc: Source address
;; @param de: Size
;; @effect hl: Destination end address
;; @effect bc: Source end address
;; @effect de: Zero
MemoryCopy::
    ; Use the fast code-path to copy pages until there are no full pages left
    push de
    inc d
    jr .fastEntry
.fastLoop:
rept 4
    ld a, [bc]
    inc bc
    ld [hl+], a
endr
    dec e
    jr nz, .fastLoop
.fastEntry:
    ld e, $40 ; $100 / 4
    dec d
    jr nz, .fastLoop
    ; Restore de and set d to 0 to match the documented side-effect
    pop de
    ld d, 0

    ; Use the slow code-path for the rest of the memory
    inc e
    jr .slowEntry
.slowLoop:
    ld a, [bc]
    inc bc
    ld [hl+], a
.slowEntry:
    dec e
    jr nz, .slowLoop
    ret


;; @param hl: Destination address
;; @param de: Size
;; @effect  a: Zero
;; @effect hl: Destination end address
;; @effect de: Zero
MemoryClear::
    xor a, a
    ; Use fast code-path
    inc d
    jr .fastEntry
.fastLoop:
rept 8
    ld [hl+], a
endr
    dec b
    jr nz, .fastLoop
.fastEntry:
    ld b, $20 ; $100 / 8
    dec d
    jr nz, .fastLoop

    ; Use the slow code-path
    inc e
    jr .slowEntry
.slowLoop:
    ld [hl+], a
.slowEntry:
    dec e
    jr nz, .slowLoop
    ret
