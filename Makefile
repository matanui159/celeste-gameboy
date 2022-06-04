CFLAGS = -Wall -Wextra -Wpedantic
ASM_FLAGS = -Weverything
LINK_FLAGS = -wp 0xff
FIX_FLAGS = -f hg
DMG_FLAGS = --force-dmg -P 72 # "Black Zero"
CGB_FLAGS = -C 1 # SameBoy
DEBUG_FLAGS = -p

CELESTE = bin/celeste.gb
CELESTE_OBJ = \
	bin/gen/gen_tiles.obj \
	bin/src/bitmaps.obj \
	bin/gen/gen_text.obj \
	bin/gen/gen_palettes.obj \
	bin/gen/gen_attrs.obj \
	bin/gen/gen_maps.obj \
	bin/gen/gen_sfx.obj \
	bin/gen/gen_music.obj \
	bin/src/main.obj \
	bin/src/memory.obj \
	bin/src/math.obj \
	bin/src/random.obj \
	bin/src/engine/video.obj \
	bin/src/engine/object.obj \
	bin/src/engine/map.obj \
	bin/src/engine/hblank.obj \
	bin/src/engine/input.obj \
	bin/src/engine/audio.obj \
	bin/src/ui.obj \
	bin/src/objects/physics.obj \
	bin/src/objects/player.obj \
	bin/src/objects/player_hair.obj \
	bin/src/objects/player_spawn.obj \
	bin/src/objects/player_death.obj \
	bin/src/objects/fruit.obj \
	bin/src/objects/lifeup.obj \
	bin/src/objects/fake_wall.obj \
	bin/src/objects/spikes.obj \
	bin/src/objects/smoke.obj \
	bin/src/engine/fragment.obj \
	# bin/gen/gen_wrapper.obj # Turns it into a mostly-valid PNG

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
