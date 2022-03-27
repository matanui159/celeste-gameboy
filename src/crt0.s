    .area _HEADER (ABS)
    .org 0x38
_exit::
    jr _exit
    .org 0x40
    jp __int_vblank
    .org 0x100
    jp __entry

    .area _HOME
    .area _CODE
    .area _INITIALIZER

    .area _GSINIT
__entry::
    di
    ldh (0x80), a
    ld sp, #0xe000

    ld de, #s__DATA
    ld c, #0
    ld hl, #l__DATA
    push hl
    call _memset

    ld de, #s__INITIALIZED
    ld bc, #s__INITIALIZER
    ld hl, #l__INITIALIZED
    push hl
    call _memcpy

    .area _GSFINAL
    call _main
    jp _exit

    .area _DATA
    .area _INITIALIZED
    .area _BSEG
    .area _BSS
    .area _HEAP
