section "main_entry", rom0[$0100]
    nop
    jp main
    ds $4c

section "main_rom", rom0


; () => void
main:
    ld sp, main_stack.end
    call init_engine
    call run_engine


section "main_wram", wram0
main_stack: ds $100
.end:
