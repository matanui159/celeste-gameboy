section "engine_rom", rom0


; () => void
init_engine::
    di
    call init_rand
    call init_video
    ld a, $01
    ldh [REG_IE], a
    xor a, a
    ldh [REG_IF], a
    ei
    ret


; () => never
run_engine::
    ; add more entropy to the randomiser
    call rand
    call draw_video
    jr run_engine
