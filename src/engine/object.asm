include "hardware.inc"

section "object_rom", rom0


; (???) => hl
alloc_object::
    ret


; ???
free_object::
    ret


; () => void
clear_objects::
    ret


; () => void
init_objects::
    ret


section "object_wram", wram0
objects:
    ds OAM_COUNT * sizeof_OAM_ATTRS
