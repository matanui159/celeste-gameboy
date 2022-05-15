include "../hardware.inc"

rsreset
def CHANA_FLAGS    rb
def CHANA_SPEED    rb
def CHANA_START    rw
def CHANA_LENGTH   rb
def CHANA_POINTER  rw
def CHANA_NOTE     rb
def sizeof_CHANNEL rb 0

section "Timer interrupt", rom0[$0050]
    ei
    jp Timer

section "Audio ROM", rom0


;; Initialises the audio system
AudioInit::
    ; Clear out the audio memory
    ld hl, wChannelPulse0
    ld de, wChannelsEnd - wChannelPulse0
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
;; @param  b: Channel flags
;; @param de: Pointer to sound data
;; @param hl: Pointer to the channel data
PlayCommon:
    ; Flags
    ld a, b
    ld [hl+], a
    ; Speed
    ld a, [de]
    inc de
    ld [hl+], a
    ; Falls through to `RestartChannel` below


;; Restarts a channel if it is looping
;; @param de: Pointer to sound data, starting at the length byte
;; @param hl: Pointer to the channel data, starting at the start address byte
RestartChannel:
    ; Check if looping is enabled
    ld a, [de]
    ld b, a
    bit 7, b
    jr z, .noLoop
    ; Looping enabled, save the starting address so we can come back
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ; Remove the looping flag
    ld a, b
    and a, $7f
.noLoop:
    ; Looping disabled, set the start address to $0000 to indicate there is no
    ; looping
    xor a, a
    ld [hl+], a
    ld [hl+], a
    ld a, b
.start:
    ; Increment the length by 1 since we insert one dummy note
    inc a
    ld [hl+], a
    ; Current pointer
    inc de
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ; Current note length. Set to 1 so next audio frame this gets decremented to
    ; 0, causing the first note to be played
    ld [hl], 1
    ret


;; @param  d: Channel flags
;; @param de: Pointer to sound data
PlayPulse0:
    ld hl, wChannelPulse0
    ld c, low(rAUD2ENV)
    jr PlayPulse


;; @param  d: Channel flags
;; @param de: Pointer to sound data
PlayPulse1:
    ld hl, wChannelPulse1
    ld c, low(rAUD2ENV)
    ; Falls through to `PlayPulse`


;; Common code shared by both pulse channels
;; @param  b: Channel flags
;; @param  c: NRx2 register
;; @param de: Pointer to the channel data
;; @param hl: Pointer to the pulse channel data
PlayPulse:
    ; Check if we need to change the wave duty
    ld a, [hl]
    xor a, b
    and a, $f
    jr z, .dutyEnd
    ; Mute the pulse channel
    xor a, a
    ldh [c], a
    dec c
    ; Update the pulse duty
    ld a, b
    and a, $c
    swap a
    ldh [c], a
.dutyEnd:
    ; Update common channel data
    jp PlayCommon


;; @param  b: Channel flags
;; @param de: Pointer to sound data
PlayWave:
    ; Check if we need to change the wave data
    ld a, [wChannelWave]
    xor a, b
    and a, $f
    jr z, .waveEnd
    ; Get the address to the wave data we want to use
    ; TODO: support other instruments
    ld hl, WaveTri
    ld c, low(_AUD3WAVERAM)

    ; Disable and mute the wave channel
    xor a, a
    ldh [rAUD3ENA], a
    ldh [rAUD3LEVEL], a
    ; Quickly update the wave RAM
rept 16
    ld a, [hl+]
    ldh [c], a
    inc c
endr
    ; Re-enable the channel
    ld a, AUD3ENA_ON
    ldh [rAUD3ENA], a

.waveEnd:
    ; Update common data
    ld hl, wChannelWave
    jp PlayCommon


;; @param  b: Channel flags
;; @param de: Pointer to sound data
PlayNoise:
    ld hl, wChannelNoise
    jp PlayCommon


;; Starts playing a sound on a specific channel
;; @param  a: Channel flags
;; @param bc: Pointer to sound data
PlayChannel:
    ld b, a
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
    ld e, a
    ld d, [hl]

    ; Setup the first channel
    push de
    ld a, [de]
    inc de
    swap a
    and a, $0f
    call PlayChannel
    pop de

    ; Check if the second channel differs from the first
    ld a, [de]
    inc de
    ld b, a
    swap b
    cp a, b
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


;; Update code shared by all channels. Will check if there is a new note to play
;; and if so will call the provided callback with the new note in DE.
;;
;; @param hl: Pointer to the channel data
;; @param bc: Note callback
UpdateChannel:
    ; Save BC for later, this also allows us to use RET to jump to the callback
    push bc
    ; Get the speed since we might need it later
    inc hl
    ld a, [hl+]
    ld d, a
    ; Check if this channel is currently playing anything
    inc hl
    inc hl
    ld a, [hl+]
    or a, a
    jr z, .return
    ; Get the current pointer since we might need it later
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    ; Decrement the note counter, return if we are still waiting
    dec [hl]
    jr nz, .return
    ; Current note finished, start the next one
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
    ret z
.silence:
    ; This channel should play silence instead
    ld de, $0000
    ; This will jump to the BC callback we pushed earlier
    ret
.return:
    ; Pop BC so we don't call the callback
    pop bc
    ret


;; @param de: The note to play
UpdatePulse0:
    ld c, low(rAUD1ENV)
    jr UpdatePulse


;; @param de: The note to play
UpdatePulse1:
    ld c, low(rAUD2ENV)
    ; Falls through to `UpdatePulse`


;; Common code shared by both pulse channels for playing the next note
;; @param  c: NRx2 register
;; @param de: The note to play
UpdatePulse:
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


;; @param de: The note to play
UpdateWave:
    ; Extract the level into B
    ld a, d
    and a, $60
    ld b, a
    ; Extract the frequency into DE
    sla e
    ld a, d
    rla
    and a, $07
    ; Set the enable flag
    or a, AUDHIGH_RESTART
    ld d, a

    ; Update the registers
    ld a, b
    di
    ldh [rAUD3LEVEL], a
    ld a, e
    ldh [rAUD3LOW], a
    ld a, d
    ldh [rAUD3HIGH], a
    reti


;; @param de: The note to play
UpdateNoise:
    ; Extract the volume into A
    ld a, d
    and a, $e0
    ld b, a
    ; Expand to 4-bits
    and a, $80
    swap a
    add a, a
    or a, b
    ; Setup D to be the enable flag
    ld d, AUDHIGH_RESTART

    ; Update the registers
    di
    ldh [rAUD4ENV], a
    ld a, e
    ldh [rAUD4POLY], a
    ld a, d
    ldh [rAUD4GO], a
    reti


;; Timer interrupt. This is called 128 times a second to update the audio.
Timer:
    push af
    push bc
    push de
    push hl

    ; First pulse channel
    ld hl, wChannelPulse0
    ld bc, UpdatePulse0
    call UpdateChannel

    ; Second pulse channel
    ld hl, wChannelPulse1
    ld bc, UpdatePulse1
    call UpdateChannel

    ; Wave channel
    ld hl, wChannelWave
    ld bc, UpdateWave
    call UpdateChannel

    ; Noise channel
    ld hl, wChannelNoise
    ld bc, UpdateNoise
    call UpdateChannel

    pop hl
    pop de
    pop bc
    pop af
    ret


section "Audio ROMX", romx
; Just some wave tables for the wave channel

WaveTri:
    db $01, $23, $45, $67, $89, $ab, $cd, $ef
    db $fe, $dc, $ba, $98, $76, $54, $32, $10

section "Audio WRAM", wram0
wChannelPulse0: ds sizeof_CHANNEL
wChannelPulse1: ds sizeof_CHANNEL
wChannelWave: ds sizeof_CHANNEL
wChannelNoise: ds sizeof_CHANNEL
wChannelsEnd:

section "Audio HRAM", hram
hSoundChannels: db
