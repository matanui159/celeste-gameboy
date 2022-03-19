include "hardware.inc"

section "engine_rom", rom0


test_callback:
    ret


; (boot: a) => void
init_engine::
    ldh [engine_boot], a
    di
    call init_rand
    call init_video
    call init_objects

    ld bc, $4444
    ld d, $01
    ld e, $00
    ld hl, test_callback
    push hl
    call alloc_object
    pop hl

    ; TODO: put in function call
    ld a, LCDCF_BGON | LCDCF_OBJON | LCDCF_BG8000 | LCDCF_ON
    ldh [rLCDC], a

    ld a, IEF_VBLANK
    ldh [rIE], a
    xor a, a
    ldh [rIF], a
    ei
    ret


; () => never
run_engine::
    ; add more entropy to the randomiser
    call rand
    call update_objects
    call draw_video
    jr run_engine


section "engine_hram", hram
engine_boot:: db
