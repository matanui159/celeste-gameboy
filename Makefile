CFLAGS = -Wall -Wextra -Wpedantic
ASM_FLAGS = -isrc -Weverything
LINK_FLAGS = -dt
FIX_FLAGS = -vcj -t CELESTE -n 0x10 # ver. 1.0
DMG_FLAGS = --force-dmg -P 62 # BGB palette
CGB_FLAGS = -C 1 # SameBoy palette
DEBUG_FLAGS = -p

CELESTE = bin/celeste.gb
CELESTE_OBJ = \
	bin/gen/gtiles.obj \
	bin/gen/gpalettes.obj \
	bin/gen/gattrs.obj \
	bin/gen/gmaps.obj \
	bin/engine/mem.obj \
	bin/engine/rand.obj \
	bin/engine/object.obj \
	bin/engine/map.obj \
	bin/engine/video.obj \
	bin/engine/engine.obj \
	bin/main.obj

LUA = bin/celeste.lua
LUA_GEN = bin/gen/glua

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

RGBASM = rgbasm -o $@ $< -M $(@:.obj=.mak) -MP $(ASM_FLAGS)
bin/%.obj: src/%.asm
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

run-dmg: $(CELESTE)
	binjgb $< $(DMG_FLAGS)
debug-dmg: $(CELESTE)
	binjgb-debugger $< $(DMG_FLAGS) $(DEBUG_FLAGS)
run-cgb: $(CELESTE)
	binjgb $< $(CGB_FLAGS)
debug-cgb: $(CELESTE)
	binjgb-debugger $< $(CGB_FLAGS) $(DEBUG_FLAGS)
.PHONY: run-dmg debug-dmg run-cgb debug-cgb
