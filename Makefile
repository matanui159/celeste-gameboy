asm_flags = -isrc -Weverything
link_flags = -w
fix_flags = -vCj -t CELESTE -n 0x10
binjgb_flags = -C 1

celeste = celeste.gb
celeste_obj = \
	gen/celeste.obj \
	src/palette.obj \
	src/flags.obj \
	src/oam.obj \
	src/engine/mem.obj \
	src/engine/rand.obj \
	src/engine/video.obj \
	src/engine/map.obj \
	src/engine/engine.obj \
	src/main.obj

all: $(celeste)
.PHONY: all
-include $(celeste_obj:.obj=.mak)

$(celeste): $(celeste_obj)
	rgblink -o $@ $^ -m $(@:.gb=.map) $(pad_flags)
	rgbfix $@ $(fix_flags)

%.obj: %.asm
	rgbasm -o $@ $< -M $(@:.obj=.mak) -MP -isrc -Weverything

gen/node_modules:
	cd gen && npm ci
gen/%.asm: gen/%.mjs gen/celeste.p8.png gen/node_modules
	cd gen && node ../$<

binjgb: $(celeste)
	binjgb $< $(binjgb_flags)
binjgb-debug: $(celeste)
	binjgb-debugger $< -p $(binjgb_flags)
.PHONY: binjgb binjgb-debug
