CC = sdcc
CFLAGS = -msm83 --std-sdcc99 --opt-code-speed
LDFLAGS = -msm83 --no-std-crt0 --code-loc 0x150
AS = sdasgb
ASFLAGS = -og
BIN = makebin
BIN_FLAGS = -Z -yn CELESTE -yc -yj

GEN_CC = cc
GEN_CFLAGS = -Wall -Wextra -Wpedantic
GEN_LDFLAGS =

DMG_FLAGS = --force-dmg -P 62 # BGB palette
CGB_FLAGS = -C 1 # SameBoy palette
DEBUG_FLAGS = -p

CELESTE = bin/celeste.gb
CELESTE_IHX = $(CELESTE:.gb=.ihx)
CELESTE_REL = \
	bin/crt0.rel \
	bin/gen/gtiles.rel \
	bin/gen/gattrs.rel \
	bin/gen/gpalettes.rel \
	bin/gen/gmaps.rel \
	bin/engine/engine.rel \
	bin/engine/video.rel \
	bin/engine/palcpy.rel \
	bin/engine/map.rel \
	bin/engine/map_hblank.rel \
	bin/main.rel

LUA = bin/celeste.lua
LUA_GEN = bin/gen/glua

all: $(CELESTE) $(LUA)
clean:
	rm -r bin
.PHONY: all clean
-include $(CELESTE_REL:.rel=.mak) $(CELESTE_REL:.rel=.d) $(LUA_GEN:=.d)

MKDIR = mkdir -p $(dir $@)
$(CELESTE): $(CELESTE_IHX)
	$(BIN) $(BIN_FLAGS) $< $@
$(CELESTE_IHX): $(CELESTE_REL)
	$(MKDIR)
	$(CC) -o $@ $^ $(LDFLAGS)

COMPILE = $(CC) -o $@ -c $< -Wp -MMD,$(@:.rel=.mak),-MT,$@,-MP $(CFLAGS)
bin/%.rel: src/%.c
	$(MKDIR)
	$(COMPILE)
bin/%.rel: bin/%.c
	$(MKDIR)
	$(COMPILE)

bin/%.rel: src/%.s
	$(MKDIR)
	$(AS) $(ASFLAGS) $@ $<

GEN = $< > $@
bin/gen/%.c: bin/gen/% gen/celeste.p8.png
	$(MKDIR)
	$(GEN)
$(LUA): $(LUA_GEN)
	$(MKDIR)
	$(GEN)
bin/gen/%: gen/%.c
	$(MKDIR)
	$(GEN_CC) -o $@ $< -MMD -MP $(GEN_CFLAGS) $(GEN_LDFLAGS)

run-dmg: $(CELESTE)
	binjgb $< $(DMG_FLAGS)
debug-dmg: $(CELESTE)
	binjgb-debugger $< $(DMG_FLAGS) $(DEBUG_FLAGS)
run-cgb: $(CELESTE)
	binjgb $< $(CGB_FLAGS)
debug-cgb: $(CELESTE)
	binjgb-debugger $< $(CGB_FLAGS) $(DEBUG_FLAGS)
.PHONY: run-dmg debug-dmg run-cgb debug-cgb
