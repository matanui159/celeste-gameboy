include "../hardware.inc"

rsreset
def CHANA_FLAGS    rb
def CHANA_SPEED    rb
def CHANA_START    rw
def CHANA_LENGTH   rb
def CHANA_POINTER  rw
def CHANA_NOTE     rb
def sizeof_CHANNEL rb 0

rsreset
def PULSEA_EFFECT rb
def sizeof_PULSE  rb 0


section "Timer interrupt", rom0[$0050]
    ; This is called 128 times a second to update the audio
    ei
    push af
    push bc
    push de
    push hl
    call UpdatePulse0
    call UpdatePulse1
    pop hl
    pop de
    pop bc
    pop af
    ret


section "Audio ROM", rom0


;; Initialises the audio system
AudioInit::
    ; Clear out the audio memory
    ld hl, wPulse0Common
    ld de, wEnd - wPulse0Common
    call MemoryClear
    ldh [hSoundChannels], a

    ; Enable the sound controller
    ld a, AUDENA_ON
    ldh [rAUDENA], a
    ; Mute all the channels
    xor a, a
    ldh [rAUD1ENV], a
    ldh [rAUD2ENV], a
    ldh [rAUD3LEVEL], a
    ldh [rAUD4ENV], a
    ; Send all channels to both terminals
    ld a, $ff
    ldh [rAUDTERM], a
    ; Set master volume to max
    ld a, $77
    ldh [rAUDVOL], a

    ; Setup the timer interrupt. We do 32 steps at 4096Hz to reach 128Hz. This
    ; does not match teh PICO-8 audio clock but is close enough while exactly
    ; matching the GameBoy audio clock.
    ld a, -32
    ldh [rTMA], a
    ld a, TACF_4KHZ | TACF_START
    ldh [rTAC], a
    ret


;; Play code shared by all channels
;; @param  d: Channel flags
;; @param bc: Pointer to sound data
;; @param hl: Pointer to the channel data
;; @returns hl: Pointer to after the channel data (extra data)
PlayCommon:
    ; Flags
    ld a, d
    ld [hl+], a
    ; Speed
    ld a, [bc]
    inc bc
    ld [hl+], a
    ; Falls through to `RestartChannel` below


;; Restarts a channel if it is looping
;; @param bc: Pointer to sound data, starting at the length byte
;; @param hl: Pointer to the channel data, starting at the start address byte
;; @returns hl: Pointer to after the channel data (extra data)
RestartChannel:
    ; Check if looping is enabled
    ld a, [bc]
    ld d, a
    bit 7, d
    jr z, .noLoop
    ; Looping enabled, save the starting address so we can come back
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ; Remove the looping flag
    ld a, d
    and a, $7f
.noLoop:
    ; Looping disabled, set the start address to $0000 to indicate there is no
    ; looping
    xor a, a
    ld [hl+], a
    ld [hl+], a
    ld a, d
.start:
    ; Increment the length by 1 since we insert one dummy note
    inc a
    ld [hl+], a
    ; Current pointer
    inc bc
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ; Current note length. Set to 1 so next audio frame this gets decremented to
    ; 0, causing the first note to be played
    ld a, 1
    ld [hl+], a
    ret


;; @param  d: Channel flags
;; @param bc: Pointer to sound data
PlayPulse0:
    ld hl, wPulse0Common
    ld e, low(rAUD1LEN)
    jr PlayPulse


;; @param  d: Channel flags
;; @param bc: Pointer to sound data
PlayPulse1:
    ld hl, wPulse1Common
    ld e, low(rAUD2LEN)
    ; Falls through to `PlayPulse`


;; Common code shared by both pulse channels
;; @param  d: Channel flags
;; @param  e: NRx1 register
;; @param bc: Pointer to sound data
;; @param hl: Pointer to the pulse channel data
PlayPulse:
    ; Check if we need to change the wave duty
    ld a, [hl]
    xor a, d
    and a, $c
    jr z, .dutyEnd
    ; Swap E and C so we can access registers
    ld a, c
    ld c, e
    ld e, a
    ; Update the pulse duty
    ld a, d
    and a, $c
    swap a
    ldh [c], a
    ld c, e
.dutyEnd:
    ; Update common channel data
    jp PlayCommon



;; @param  d: Channel flags
;; @param bc: Pointer to sound data
PlayWave:
    ret


;; @param  d: Channel flags
;; @param bc: Pointer to sound data
PlayNoise:
    ret


;; Starts playing a sound on a specific channel
;; @param  a: Channel flags
;; @param bc: Pointer to sound data
PlayChannel:
    ld d, a
    and a, $3
    or a, a
    jp z, PlayPulse0
    cp a, 2
    jp c, PlayPulse1
    jp z, PlayWave
    jp PlayNoise


;; Plays a sound effect
;; @param b: The sound to play
;; @param c: Priority, higher priority sounds cannot be overriden by lower
;;           priority ones. Sounds of the same priority can override each other.
AudioPlaySound::
    ; TODO: implement priority
    ; TODO: properly stop previous sound
    ; Disable the timer interrupt while we're in critical code
    ld hl, rIE
    res IEB_TIMER, [hl]
    ; Get the sound pointer from the lookup table
    ld h, high(GenSoundTable)
    ld l, b
    sla l
    ld a, [hl+]
    ld c, a
    ld b, [hl]

    ; Setup the first channel
    push bc
    ld a, [bc]
    inc bc
    swap a
    and a, $0f
    call PlayChannel
    pop bc

    ; Check if the second channel differs from the first
    ld a, [bc]
    inc bc
    ld d, a
    swap a
    cp a, d
    jr z, .return
    ; If it doesn't, setup the second channel
    and a, $0f
    ; Set bit 4 to indicate this is the second channel
    set 4, a
    call PlayChannel

.return:
    ; Re-enable the timer interrupt and return
    ld hl, rIE
    set IEB_TIMER, [hl]
    ret


;; Update code shared by all channels. If there is nothing to do will pop the 
;; stack twice causing the calling routine to also exit. Otherwise, will return
;; the next note to play.
;;
;; @param hl: Pointer to the channel data
;; @returns hl: Pointer to after the channel data (extra data)
;; @returns de: Next note to play
UpdateCommon:
    ; Get the speed since we might need it later
    inc hl
    ld a, [hl+]
    ld d, a
    ; Check if this channel is currently playing anything
    inc hl
    inc hl
    ld a, [hl+]
    or a, a
    jr z, .returnCaller
    ; Get the current pointer since we might need it later
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    ; Decrement the note counter, exit if we are still waiting
    dec [hl]
    jr nz, .returnCaller
    ; Current note finished, start the next one
    ; Push HL for now so we can jump back here later
    push hl
    ; Restart the note using the speed
    ld a, d
    ld [hl-], a
    ; Read the next note into DE
    ld a, [bc]
    ld e, a
    inc bc
    ld a, [bc]
    inc bc
    ld d, a
    ; Save the new pointer
    ld a, b
    ld [hl-], a
    ld a, c
    ld [hl-], a
    ; Decrement the length
    ; TODO: support looping
    ld a, [hl]
    dec a
    ld [hl-], a
    jr z, .silence
    ; Check if this note is intended for this channel
    ld bc, -3
    add hl, bc
    ld a, d
    xor a, [hl]
    bit 4, a
    jr z, .return
.silence:
    ; This channel should play silence instead
    ld de, $0000
.return:
    ; Set HL to the end of the channel data
    pop hl
    inc hl
    ret
.returnCaller:
    ; MWA HA HA I *WILL* DO EVIL STACK MANIPULATION AND NO ONE CAN STOP ME C:<
    pop bc
    ret


;; Updates the first pulse channel
UpdatePulse0:
    ld hl, wPulse0Common
    call UpdateCommon
    ld c, low(rAUD1ENV)
    jr UpdatePulseNote


;; Updates the second pulse channel
UpdatePulse1:
    ld hl, wPulse1Common
    call UpdateCommon
    ld c, low(rAUD2ENV)
    ; Falls through to `UpdatePulseNote`


;; Common code shared by both pulse channels for playing the next note
;; @param hl: Pointer to the pulse data
;; @param de: The note to play
;; @param  c: NRx2 register
UpdatePulseNote:
    ; Extract the volume into B
    ld a, d
    and a, $e0
    ld b, a
    ; Expand to 4-bits by repeating the highest bit
    and a, $80
    swap a
    add a, a
    or a, b
    ld b, a
    ; Extract the frequency into DE, frequency has to be shifted left by 1
    sla e
    ld a, d
    rla
    and a, $07
    ; Set the enable flag as well so it is ready
    or a, AUDHIGH_RESTART
    ld d, a

    ; Update the registers as fast as possible, in a critical code block
    ld a, b
    di
    ldh [c], a
    inc c
    ld a, e
    ldh [c], a
    inc c
    ld a, d
    ldh [c], a
    reti


section "Audio WRAM", wram0
wPulse0Common: ds sizeof_CHANNEL
wPulse0: ds sizeof_PULSE
wPulse1Common: ds sizeof_CHANNEL
wPulse1: ds sizeof_PULSE
wEnd:

section "Audio HRAM", hram
hSoundChannels: db
