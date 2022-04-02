if !def(REG_INC)
def REG_INC equ 1

def MEM_TILE_DATA0 equ $8000
def MEM_TILE_DATA1 equ $8800
def MEM_TILE_DATA2 equ $9000
def MEM_TILE_MAP0  equ $9800
def MEM_TILE_MAP1  equ $9c00

def MAP_ATTR_PALETTE equ $07
def MAP_ATTR_BANK1   equ $08
def MAP_ATTR_FLIP_X  equ $20
def MAP_ATTR_FLIP_Y  equ $40
def MAP_ATTR_PRIO    equ $80

def MEM_OAM equ $fe00

rsreset
def OAM_Y     rb  1
def OAM_X     rb  1
def OAM_TILE  rb  1
def OAM_ATTR  rb  1
def OAM_SIZE  rb  0
def OAM_COUNT equ 40

def OAM_X_OFFSET     equ 8
def OAM_Y_OFFSET     equ 16
def OAM_ATTR_PALETTE equ $07
def OAM_ATTR_BANK1   equ $08
def OAM_ATTR_FLIP_X  equ $20
def OAM_ATTR_FLIP_Y  equ $40
def OAM_ATTR_NO_PRIO equ $80

def REG_JOYP equ $ff00
def JOYP_RIGHT  equ $01
def JOYP_A      equ $01
def JOYP_LEFT   equ $02
def JOYP_B      equ $02
def JOYP_UP     equ $04
def JOYP_SELECT equ $04
def JOYP_DOWN   equ $08
def JOYP_START  equ $08
def JOYP_NO_DIR equ $10
def JOYP_NO_ACT equ $20

def REG_DIV equ $ff04

def REG_IF equ $ff0f
def REG_IE equ $ffff
def INT_VBLANK equ $01
def INT_STAT   equ $02
def INT_TIMA   equ $04
def INT_SERIAL equ $08
def INT_JOYP   equ $10

def REG_LCDC equ $ff40
def LCDC_BG_PRIO  equ $01
def LCDC_OBJ_ON   equ $02
def LCDC_OBJ_16   equ $04
def LCDC_BG_MAP1  equ $08
def LCDC_BG_DATA0 equ $10
def LCDC_WIN_ON   equ $20
def LCDC_WIN_MAP1 equ $40
def LCDC_ON       equ $80
def LCDC_WIDTH    equ 160
def LCDC_HEIGHT   equ 144

def REG_STAT equ $ff41
def STAT_MODE        equ $03
def STAT_LYC         equ $04
def STAT_INT_HBLANK  equ $08
def STAT_INT_VBLANK  equ $10
def STAT_INT_OAM     equ $20
def STAT_INT_LYC     equ $40
def STAT_MODE_HBLANK equ  $0
def STAT_MODE_VBLANK equ  $1
def STAT_MODE_OAM    equ  $2
def STAT_MODE_DRAW   equ  $3

def REG_SCY equ $ff42
def REG_SCX equ $ff43

def REG_DMA equ $ff46

def REG_VBK equ $ff4f

def REG_HDMA_HISRC equ $ff51
def REG_HDMA_LOSRC equ $ff52
def REG_HDMA_HIDST equ $ff53
def REG_HDMA_LODST equ $ff54
def REG_HDMA       equ $ff55
def HDMA_HBLANK equ $80

def REG_BGPI equ $ff68
def REG_BGPD equ $ff69
def REG_OBPI equ $ff6a
def REG_OBPD equ $ff6b
def PI_INC equ $80

endc
