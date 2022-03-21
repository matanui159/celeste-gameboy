include "hardware.inc"

section "engine_rst00", rom0[$0000]
    jp hl

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
    call init_map_system

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
