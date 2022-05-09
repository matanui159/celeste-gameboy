include "../hardware.inc"

section "Spikes ROM", rom0


;; Performs collision in the up direction
;; @param  a: Tile ID
;; @param hl: Tile address
;; @param bc: Collide position
;; @saved hl
;; @saved bc
SpikeCollideUp::
    ; Check that the speed is positive as well, we only need the high byte
    ld a, [wPlayerSpeedY + 1]
    bit 7, a
    ret nz
    ; Undo Y position offsets
    ldh a, [rSCY]
    add a, c
    ; We don't have to subtract OAM offsets since we only need to modulo 8 of
    ; the position and both offsets are multiples of 8.
    ; Kill the player if the point is in the lower 2 rows of this tile
    and a, $07
    cp a, 6
    ret c
    push hl
    push bc
    call PlayerDeathKill
    pop bc
    pop hl
    ret


;; Performs collision in the down direction
SpikeCollideDown::
    ; Skip if speed is non-zero positive
    push hl
    ld hl, wPlayerSpeedY + 1
    ld a, [hl-]
    bit 7, a
    jr nz, .neg
    or a, a
    jr nz, .return
    ; At this point we know A is zero so we can use it to compare to [hl]
    cp a, [hl]
    jr nz, .return
.neg:
    ; Undo offsets
    ldh a, [rSCY]
    add a, c
    ; Kill if in upper 3 rows. Note that in the original Celeste for some reason
    ; the up & left spikes have a hitbox size of 2, while the down & right
    ; spikes have a hitbox size of 3. Not sure if that is intentional but it is
    ; replicated here.
    and a, $07
    cp a, 3
    jr nc, .return
    push bc
    call PlayerDeathKill
    pop bc
.return:
    pop hl
    ret


;; Performs collision in the right direction
SpikeCollideRight::
    ; Skip if speed is non-zero positive
    push hl
    ld hl, wPlayerSpeedX + 1
    ld a, [hl-]
    bit 7, a
    jr nz, .neg
    or a, a
    jr nz, .return
    cp a, [hl]
    jr nz, .return
.neg:
    ; Undo offsets
    ldh a, [rSCX]
    add a, b
    ; Kill if in left 3 columns
    and a, $07
    cp a, 3
    jr nc, .return
    push bc
    call PlayerDeathKill
    pop bc
.return:
    pop hl
    ret


;; Performs collision in the left direction
SpikeCollideLeft::
    ; Skip if speed is negative
    ld a, [wPlayerSpeedX + 1]
    bit 7, a
    ret nz
    ; Undo offsets
    ldh a, [rSCX]
    add a, b
    ; Kill if in right 2 columns
    and a, $07
    cp a, 6
    ret c
    push hl
    push bc
    call PlayerDeathKill
    pop bc
    pop hl
    ret
