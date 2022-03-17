CFLAGS = -Wall -Wextra -Wpedantic
ASM_FLAGS = -isrc -Weverything
LINK_FLAGS = -w
FIX_FLAGS = -vCj -t CELESTE -n 0x10
BINJGB_FLAGS = -C 1

CELESTE = bin/celeste.gb
CELESTE_OBJ = \
	bin/gen/gtiles.obj \
	bin/gen/gmaps.obj \
	bin/palette.obj \
	bin/flags.obj \
	bin/oam.obj \
	bin/engine/mem.obj \
	bin/engine/rand.obj \
	bin/engine/object.obj \
	bin/engine/video.obj \
	bin/engine/map.obj \
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

binjgb: $(CELESTE)
	binjgb $< $(BINJGB_FLAGS)
binjgb-debug: $(CELESTE)
	binjgb-debugger $< -p $(BINJGB_FLAGS)
.PHONY: binjgb binjgb-debug
