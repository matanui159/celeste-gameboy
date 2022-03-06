gen = gen/celeste.asm
asm = \
	$(gen) \
	src/palette.asm \
	src/engine/reg.asm \
	src/engine/mem.asm \
	src/engine/rand.asm \
	src/engine/video.asm \
	src/engine/engine.asm \
	src/main.asm
obj = $(asm:.asm=.obj)
gb = celeste.gb
map = $(gb:.gb=.map)

all: $(gb)
clean:
	$(RM) $(gen) $(obj) $(gb) $(map)
.PHONY: all clean

$(gb): $(obj)
	rgblink -o $@ $^ -m $(map)
	rgbfix $@ -vCj -t CELESTE -l 0x33 -k 00
%.obj: %.asm
	rgbasm -o $@ $^ -Weverything

$(gen): gen/index.mjs gen/celeste.p8.png gen/node_modules
	cd gen && npm run gen
gen/node_modules:
	cd gen && npm ci

binjgb: $(gb)
	binjgb $(gb) -C 1
binjgb-debug: $(gb)
	binjgb-debugger $(gb) -C 1 -p
.PHONY: binjgb binjgb-debug
