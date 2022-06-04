include "hardware.inc"

section "UI ROM", rom0


;; Initializes the UI rendering
UIInit::
    ; Reset the timer
    xor a, a
    ldh [hFrames], a
    ldh [hSeconds], a
    ldh [hMinutes], a
    ldh [hHours], a
    ; Draw the time as 00::00::00
    ; Hours
    ld a, 0 + $84
    ld bc, vTime
    call MapQueueUpdate
    ; Seperator
    ld a, 110 + $84
    ld bc, vTime + 1
    call MapQueueUpdate
    ; Minutes
    ld a, 0 + $84
    ld bc, vTime + 2
    call MapQueueUpdate
    ; Seperator
    ld a, 110 + $84
    ld bc, vTime + 3
    call MapQueueUpdate
    ; Seconds
    ld a, 0 + $84
    ld bc, vTime + 4
    jp MapQueueUpdate


;; Updates the UI
UIUpdate::
    ldh a, [hTitleTimer]
    or a, a
    ret z
    dec a
    ldh [hTitleTimer], a
    ret


;; Update the UI timer. This is called by the audio interrupt since it is
;; based on actual timers so will be alot closer to 1s.
UIUpdateTimer::
    ; TODO: add ability to start/stop the timer
    ldh a, [hFrames]
    inc a
    cp a, 128
    jr c, .framesEnd
    ; Every 128 frames, add 1 second
    ldh a, [hSeconds]
    inc a
    cp a, 60
    jr c, .secondsEnd
    ; Every 60 seconds, add 1 minute
    ldh a, [hMinutes]
    inc a
    cp a, 60
    jr c, .minutesEnd
    ; Every 60 minutes, add 1 hour
    ldh a, [hHours]
    inc a
    cp a, 100
    jr c, .hoursEnd
    ; TODO: maybe do something else other than overflow??
    xor a, a
.hoursEnd:
    ldh [hHours], a
    ; Update the hours
    add a, $84
    ld bc, vTime
    call MapQueueUpdate
    xor a, a
.minutesEnd:
    ldh [hMinutes], a
    ; Update the minutes
    add a, $84
    ld bc, vTime + 2
    call MapQueueUpdate
    xor a, a
.secondsEnd:
    ldh [hSeconds], a
    ; Update the seconds, the first pair of digits start at index $84
    add a, $84
    ld bc, vTime + 4
    call MapQueueUpdate
    xor a, a
.framesEnd:
    ldh [hFrames], a
    ret


;; Temporarily shows the title and the timer
UIShowTitle::
    ; TODO: show the actual title itself, not just the timer
    ld a, 35
    ldh [hTitleTimer], a
    ret


;; H-blank interrupt handler to start drawing the title
UIDrawTimer::
    push af
    push hl
    ; Check if the title is being shown
    ldh a, [hShowTitle]
    or a, a
    jr z, .return
    ; Setup the window scroll registers
    ld a, 110
    ldh [rWX], a
    ; Window Y position is reallyyyy weird, from my limited understanding:
    ; - Window only starts drawing when WY=LY which it checks at the start of
    ;   each row
    ; - When it does start drawing, it starts by rendering its first row and
    ;   only increments its counter while drawing
    ld a, 12
    ldh [rWY], a
    ; Enable the window
    ldh a, [rLCDC]
    set LCDCB_WINON, a
    call HBlankUpdateLCDC
.return:
    ; Setup interrupt for hiding the timer at line 18
    ld a, 18
    ld hl, HideTimer
    call HBlankSet
    pop hl
    pop af
    reti


;; Hides the timer window after it has been rendering for a few rows
HideTimer:
    push af
    push hl
    ; Disable the window
    ldh a, [rLCDC]
    res LCDCB_WINON, a
    call HBlankUpdateLCDC
    ; Setup interrupt for disabling objects at line 135
    ld a, 135
    ld hl, HBlankDisableObjects
    call HBlankSet
    pop hl
    pop af
    reti


section fragment "VBlank", rom0
UIVBlank:
    ldh a, [hTitleTimer]
    or a, a
    jr z, .hideTitle
    cp a, 30
    jr nc, .hideTitle
    ; Show the title
    ld a, 1
    ldh [hShowTitle], a
    jr .end
.hideTitle:
    ; Hide the title
    xor a, a
    ldh [hShowTitle], a
.end:


section "UI VRAM", vram[_SCRN1]
vTime: ds SCRN_VX_B
ds SCRN_VX_B
vTitle: ds SCRN_VX_B

section "UI HRAM", hram
hFrames: db
hSeconds: db
hMinutes: db
hHours: db
hTitleTimer: db
hShowTitle: db
