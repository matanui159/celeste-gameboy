section "engine_rom", rom0


; () => void
init_engine::
    di
    call init_rand
    call init_video
    ld a, $05
    ldh [REG_IE], a
    xor a, a
    ldh [REG_IF], a
    ei
    ret


; () => never
run_engine::
    call draw_video
    jr run_engine
