CFLAGS = -Wall -Wextra -Wpedantic
ASM_FLAGS = -Weverything
LINK_FLAGS = -tw
FIX_FLAGS = -vCj -t CELESTE -n 0x10 # ver. 1.0
BINJGB_FLAGS = -C 1
DEBUG_FLAGS = -p

CELESTE = bin/celeste.gb
CELESTE_OBJ = \
	bin/gen/gen_tiles.obj \
	bin/gen/gen_pals.obj \
	bin/gen/gen_attrs.obj \
	bin/gen/gen_maps.obj \
	bin/src/main.obj \
	bin/src/memory.obj \
	bin/src/random.obj \
	bin/src/video.obj \
	bin/src/object.obj \
	bin/src/map.obj \
	bin/src/input.obj \
	bin/src/physics.obj \
	bin/src/player.obj \
	bin/src/fragment.obj

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
	rgblink -o $@ $^ -m $(@:.gb=.map) $(LINK_FLAGS)
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

binjgb: $(CELESTE)
	binjgb $< $(BINJGB_FLAGS)
binjgb-debug: $(CELESTE)
	binjgb-debugger -p $< $(BINJGB_FLAGS)
.PHONY: binjgb binjgb-debug
