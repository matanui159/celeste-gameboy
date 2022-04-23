CFLAGS = -Wall -Wextra -Wpedantic
ASM_FLAGS = -Weverything
LINK_FLAGS = -w
FIX_FLAGS = -vcj -t CELESTE -n 0x10 # ver. 1.0
DMG_FLAGS = --force-dmg -P 72 # "Black Zero"
CGB_FLAGS = -C 1 # SameBoy
DEBUG_FLAGS = -p

CELESTE = bin/celeste.gb
CELESTE_OBJ = \
	bin/gen/gen_tiles.obj \
	bin/gen/gen_palettes.obj \
	bin/gen/gen_attrs.obj \
	bin/gen/gen_maps.obj \
	bin/src/main.obj \
	bin/src/memory.obj \
	bin/src/random.obj \
	bin/src/engine/video.obj \
	bin/src/engine/object.obj \
	bin/src/engine/map.obj \
	bin/src/engine/input.obj \
	bin/src/engine/fragment.obj \
	bin/src/objects/physics.obj \
	bin/src/objects/player.obj \
	bin/src/objects/smoke.obj

LUA = bin/celeste.lua
LUA_GEN = bin/gen/gen_lua

all: $(CELESTE) $(LUA)
clean:
	rm -r bin
.PHONY: all clean
-include $(CELESTE_OBJ:.obj=.mak) $(CELESTE_OBJ:.obj=.d) $(LUA_GEN:=.d)

MKDIR = mkdir -p $(dir $@)
$(CELESTE): $(CELESTE_OBJ)
	$(MKDIR)
	rgblink -o $@ $^ -n $(@:.gb=.sym) -m $(@:.gb=.map) $(LINK_FLAGS)
	rgbfix $@ $(FIX_FLAGS)

RGBASM = rgbasm -o $@ $< -i $(dir $<) -M $(@:.obj=.mak) -MP $(ASM_FLAGS)
bin/%.obj: %.asm
	$(MKDIR)
	$(RGBASM)
bin/%.obj: bin/%.asm
	$(MKDIR)
	$(RGBASM)

GEN = $< > $@
bin/gen/%.asm: bin/gen/% gen/celeste.p8.png
	$(MKDIR)
	$(GEN)
$(LUA): $(LUA_GEN)
	$(MKDIR)
	$(GEN)
bin/gen/%: gen/%.c
	$(MKDIR)
	$(CC) -o $@ $< -MMD -MP $(CFLAGS)

dmg-run: $(CELESTE)
	binjgb $< $(DMG_FLAGS)
dmg-debug: $(CELESTE)
	binjgb-debugger $< $(DMG_FLAGS) $(DEBUG_FLAGS)
cgb-run: $(CELESTE)
	binjgb $< $(CGB_FLAGS)
cgb-debug: $(CELESTE)
	binjgb-debugger $< $(CGB_FLAGS) $(DEBUG_FLAGS)
.PHONY: dmg-run dmg-debug cgb-run cgb-debug
