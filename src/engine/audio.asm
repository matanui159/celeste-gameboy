include "../hardware.inc"

rsreset
def CHANA_START   rw
def CHANA_FLAGS   rb
def CHANA_SPEED   rb
def CHANA_LENGTH  rb
def CHANA_NOTE    rb
def CHANA_POINTER rw
def sizeof_CHANNEL equ _RS

section "Timer interrupt", rom0[$0050]
    ei
    jp Timer

section "Audio ROM", rom0


;; Initialises the audio system
AudioInit::
    ; Clear out the audio memory
    ld hl, wSoundPulse0
    ld de, wEnd - wSoundPulse0
    call MemoryClear
    ; Clear the current music
    ldh [hMusicLength], a

    ; Enable the sound controller
    ld a, AUDENA_ON
    ldh [rAUDENA], a
    ; Mute all the channels
    xor a, a
    ldh [rAUD1ENV], a
    ldh [rAUD2ENV], a
    ldh [rAUD3LEVEL], a
    ldh [rAUD4ENV], a
    ; Set the first pulse channel to 12.5%. We only update the duty if it
    ; differs from the previous flags and since it is reset to 0, if there was
    ; a duty of %00 requested, there would be no update. This only affects the
    ; first channels since it also has a channel ID of %00.
    ldh [rAUD1LEN], a
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


;; Gets the sound pointer from the lookup table
;; @param a: Sound ID
;; @returns de: Pointer to the sound data
GetSoundAddr:
    ld h, high(GenSoundTable)
    add a, a
    ld l, a
    ld a, [hl+]
    ld e, a
    ld d, [hl]
    ret


;; Gets the address of the specified channel
;; @param a: Channel flags
;; @returns hl: Pointer to the channel data
GetChannelAddr:
    and a, $3
    or a, a
    jr z, .pulse0
    cp a, 2
    jr c, .pulse1
    jr z, .wave
    ld hl, wSoundNoise
    ret
.pulse0:
    ld hl, wSoundPulse0
    ret
.pulse1:
    ld hl, wSoundPulse1
    ret
.wave:
    ld hl, wSoundWave
    ret


;; @param  b: Channel flags
SetPulse0Duty:
    ld c, low(rAUD1ENV)
    jr SetPulseDuty


;; @param  b: Channel flags
SetPulse1Duty:
    ld c, low(rAUD2ENV)
    ; Falls through to `SetPulseDuty`


;; Common code shared by both pulse channels for setting the pulse duty
;; @param  b: Channel flags
;; @param  c: NRx2 register
SetPulseDuty:
    ; Mute the pulse channel
    xor a, a
    ldh [c], a
    dec c
    ; Update the pulse duty
    ld a, b
    and a, $c0
    ldh [c], a
    ret


;; @param  b: Channel flags
SetWavePattern:
    ; Disable and mute the wave channel
    xor a, a
    ldh [rAUD3ENA], a
    ldh [rAUD3LEVEL], a
    ; Get the address to the wave data we want to use
    ld a, b
    and a, $c0
    ; Patterns 0, 1 and 2 are shifted left by 6 so we have to compare against
    ; $40 to check them
    cp a, $40
    jr c, .triPattern
    jr z, .sawPattern
    ld hl, WaveOrg
    jr .setPattern
.triPattern:
    ld hl, WaveTri
    jr .setPattern
.sawPattern:
    ld hl, WaveSaw

.setPattern:
    ld c, low(_AUD3WAVERAM)
    ; Quickly update the wave RAM
rept 16
    ld a, [hl+]
    ldh [c], a
    inc c
endr

    ; Re-enable the channel
    ld a, AUD3ENA_ON
    ldh [rAUD3ENA], a
    ; We know what HL would have been so restore it to that
    ld hl, wSoundWave + CHANA_SPEED
    ret


;; Sets the channel flags, updated the audio registers if it needs to
;; @param  a: Channel flags
;; @param hl: Pointer to the current channel flags
;; @returns hl: Pointer to the channel speed
SetChannelFlags:
    ld c, [hl]
    ld [hl+], a
    ; Check if we need to change the hardware registers
    ld b, a
    xor a, c
    and a, $c3
    ret z
    ; Check which channel we are to update said registers
    ld a, b
    and a, $03
    or a, a
    jp z, SetPulse0Duty
    cp a, 2
    jp c, SetPulse1Duty
    jp z, SetWavePattern
    ; Noise channel does not change anything
    ret


;; Sets up a channel to start playing a sound on the next audio frame
;; @param de: Pointer to sound data
;; @param hl: Pointer to the channel speed
PlaySound:
    ; Speed
    ld a, [de]
    inc de
    ld [hl+], a
    ; Length
    ld a, [de]
    inc de
    ; Increment the length by 1 since we insert one dummy note
    inc a
    ld [hl+], a
    ; Current note length. Set to 1 so next audio frame this gets decremented to
    ; 0, causing the first note to be played
    ld a, 1
    ld [hl+], a
    ; Current pointer
    ld a, e
    ld [hl+], a
    ld [hl], d
    ret


;; Plays a sound effect
;; @param a: The sound to play
AudioPlaySound::
    ; Disable the timer interrupt while we're in critical code
    ld hl, rIE
    res IEB_TIMER, [hl]
    call GetSoundAddr
    ; Get the channel flags and write the start address
    ld a, [de]
    ld b, a
    call GetChannelAddr
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ; Setup the flags and play the sound
    ld a, b
    call SetChannelFlags
    inc de
    call PlaySound
    ; Re-enable the timer interrupt and return
    ld hl, rIE
    set IEB_TIMER, [hl]
    ret


;; Starts playing a music track
;; @param bc: Pointer to the music track
AudioPlayMusic::
    ; Disable the timer interrupt
    ld hl, rIE
    res IEB_TIMER, [hl]
    ; Save the music track pointer to both the start address and current pointer
    ld hl, wMusicStart
rept 2
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
endr
    ; Set the music length and note such that the next frame the first set of
    ; sounds is played
    ld a, 1
    ldh [hMusicLength], a
    ldh [hMusicNote], a
    ret
    ; Enable the timer interrupt
    ld hl, rIE
    set IEB_TIMER, [hl]
    ret


;; Update code shared by all channels. Will check if there is a new note to play
;; and if so will call the provided callback with the new note in DE.
;;
;; @param hl: Pointer to the channel flags
;; @param bc: Note callback
UpdateVirtualChannel:
    ; Save BC for later, this also allows us to use RET to jump to the callback
    push bc
.retry:
    ; Get the flags for later
    ld a, [hl+]
    ld b, a
    ; Get the speed for later
    ld a, [hl+]
    ld c, a
    ; Check if this channel is currently playing anything
    ld a, [hl+]
    or a, a
    jr z, .return
    ; Save the length for later
    ld d, a
    ; Decrement the note counter, return if we are still waiting
    dec [hl]
    jr nz, .return
    ; Current note finished, start the next one
    ; Restart the note using the speed
    ld a, c
    ld [hl-], a
    ; Decrement the length
    dec d
    ld a, d
    ld [hl+], a
    jr z, .end
    ; Read the current pointer
    inc hl
    ld a, [hl+]
    ld c, a
    ld b, [hl]
    ; Read the next note into DE
    ld a, [bc]
    inc bc
    ld e, a
    ld a, [bc]
    inc bc
    ld d, a
    ; Save the new pointer
    ld a, b
    ld [hl-], a
    ld [hl], c
    ; This will jump to the BC callback we pushed earlier
    ret
.end:
    ; Sound has just ended
    ; Unless looping is enabled, we make the channel play a silent note to stop
    ; the channel
    ld de, $0000
    ; Check if looping is enabled
    bit 2, b
    ret z
    ; Go back to the start address, we are currently pointing at the note
    ld bc, CHANA_START - CHANA_NOTE
    add hl, bc
    ; Read out the start address
    ld a, [hl+]
    ld e, a
    ld a, [hl+]
    ld d, a
    inc de
    ; Replay the sound
    inc hl
    call PlaySound
    ; We need to get back to the channel flags. It just so happens that the
    ; difference between start and note (-5) is the same difference between
    ; flags and the high byte of pointer (-5).
    add hl, bc
    ; Try playing the new next note
    jr .retry
.return:
    ; Pop BC so we don't call the callback
    pop bc
    ret


;; A special update callback that just returns again
UpdateNothing:
    ret


;; Update a physical channel by figuring out which virtual channel
;; (music or sound) should play.
;; @param hl: Pointer to the channel length
;; @param bc: Note callback
UpdateChannel:
    ; Check if the sound channel is playing anything
    ld a, [hl]
    or a, a
    jr z, .updateMusic
    ; Update the sound channel
    push hl
    dec hl
    dec hl
    call UpdateVirtualChannel
    ; Check if the sound is now finished
    pop hl
    ld a, [hl]
    or a, a
    jr nz, .silenceMusic
    ; If the sound is now finished, update the channel flags back to the music
    ; Save HL to BC
    ld b, h
    ld c, l
    ; Read out the music flags
    ld hl, sizeof_CHANNEL + CHANA_FLAGS - CHANA_LENGTH
    add hl, de
    ld a, [hl]
    ; Restore HL and point it to the flags
    ld h, b
    ld l, c
    dec hl
    dec hl
    ; Update the flags
    call SetChannelFlags
    inc hl
    ; We still silence it since by this point we have completely lost BC, so
    ; there is no way to update the music (unless we used the stack more but eh)
.silenceMusic:
    ; Replace BC with the NO-OP handler
    ld bc, UpdateNothing
.updateMusic:
    ; Update the music channel
    ld de, sizeof_CHANNEL + CHANA_FLAGS - CHANA_LENGTH
    add hl, de
    jp UpdateVirtualChannel


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
    ; Mask out the frequency from DE
    ld a, d
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
    ld a, d
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

    ; Update the music
    ; Check if any music is playing
    ldh a, [hMusicLength]
    or a, a
    jr z, .musicEnd
    ; Save length for later
    ld b, a
    ; Check if the current note is finished
    ldh a, [hMusicNote]
    dec a
    ldh [hMusicNote], a
    jr nz, .musicEnd
    ; Note is finished, decrement the length
    dec b
    ld a, b
    ldh [hMusicLength], a
    jr nz, .nextNote
    ; If the length reaches 0, play the next set of sounds
    ; Setup all the music channels such that unless they get overriden they will
    ; stop with the next update
    ld a, 1
    ld hl, wMusicPulse0 + CHANA_LENGTH
    ld bc, 2 * sizeof_CHANNEL
rept 4
    ld [hl+], a
    ld [hl-], a
    add hl, bc
endr
    ; Set the length of this frame to 32 notes (the maximum) and clear the
    ; speed such that we can find the slowest speed
    ld a, 32
    ldh [hMusicLength], a
    xor a, a
    ldh [hMusicSpeed], a
    ; Read out the pointer
    ld hl, wMusicPointer
    ld a, [hl+]
    ld h, [hl]
    ld l, a

.musicLoop:
    ; Keep starting sounds until the bit 6 is set
    ld a, [hl+]
    push af
    push hl
    ; Sound ID is in lower 6 bits
    and a, $3f
    call GetSoundAddr
    ; Read out the flags and channel address
    ld a, [de]
    call GetChannelAddr
    ; Check if the channel is currently occupied
    ld bc, CHANA_LENGTH
    add hl, bc
    ld a, [hl-]
    or a, a
    jr nz, .playMusic
    ; It isn't occupied, we can setup the flags now
    ld a, [de]
    dec hl
    call SetChannelFlags
.playMusic:
    ; Get a pointer to the music channel
    ld bc, sizeof_CHANNEL - CHANA_SPEED
    add hl, bc
    ; Save the start address and flags
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld a, [de]
    inc de
    ld [hl+], a
    ; Comare the sound speed to the music speed, storing the larger value
    ld a, [de]
    ld b, a
    ldh a, [hMusicSpeed]
    cp a, b
    jr nc, .maxMusicSpeed
    ; The music speed is less than this channel, swap it
    ld a, b
.maxMusicSpeed:
    ldh [hMusicSpeed], a
    ; Start the music channel
    call PlaySound
    ; End the loop, get more if bit 6 is still zero
    pop hl
    pop af
    bit 6, a
    jr z, .musicLoop
    
    ; Check if that was the last music frame by checking bit 7
    bit 7, a
    jr z, .saveMusic
    ; Use the start address for the next pointer
    ld hl, wMusicStart
    ld a, [hl+]
    ld h, [hl]
    ld l, a
.saveMusic:
    ; Save the music pointer
    ld a, l
    ld b, h
    ld hl, wMusicPointer
    ld [hl+], a
    ld [hl], b
.nextNote:
    ; Copy the speed over to the note for the next note
    ldh a, [hMusicSpeed]
    ldh [hMusicNote], a
.musicEnd:

    ; First pulse channel
    ld hl, wSoundPulse0 + CHANA_LENGTH
    ld bc, UpdatePulse0
    call UpdateChannel

    ; Second pulse channel
    ld hl, wSoundPulse1 + CHANA_LENGTH
    ld bc, UpdatePulse1
    call UpdateChannel

    ; Wave channel
    ld hl, wSoundWave + CHANA_LENGTH
    ld bc, UpdateWave
    call UpdateChannel

    ; Noise channel
    ld hl, wSoundNoise + CHANA_LENGTH
    ld bc, UpdateNoise
    call UpdateChannel

    pop hl
    pop de
    pop bc
    pop af
    ret


section "Audio ROMX", romx
; Just some wave patterns for the wave channel

WaveTri:
    db $01, $23, $45, $67, $89, $ab, $cd, $ef
    db $fe, $dc, $ba, $98, $76, $54, $32, $10

WaveSaw:
    ; This is actually the tilted-saw intrument but it sounds better, more SFX
    ; uses it, and true saw waves can be closely emulated with a 75% pulse wave.
    db $01, $12, $23, $34, $45, $66, $77, $88
    db $99, $ab, $bc, $cd, $de, $ef, $fa, $50

WaveOrg:
    db $02, $46, $9b, $df, $fd, $b9, $64, $20
    db $01, $23, $45, $67, $76, $54, $32, $10

section "Audio WRAM", wram0
wSoundPulse0: ds sizeof_CHANNEL
wMusicPulse0: ds sizeof_CHANNEL
wSoundPulse1: ds sizeof_CHANNEL
wMusicPulse1: ds sizeof_CHANNEL
wSoundWave:   ds sizeof_CHANNEL
wMusicWave:   ds sizeof_CHANNEL
wSoundNoise:  ds sizeof_CHANNEL
wMusicNoise:  ds sizeof_CHANNEL
wEnd:
wMusicStart: dw
wMusicPointer: dw

section "Audio HRAM", hram
hMusicSpeed: db
hMusicLength: db
hMusicNote: db
