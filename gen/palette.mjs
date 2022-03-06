const PICO_PALETTE = [
    { color: 0x000000, name: 'BLACK' },
    { color: 0x1d2b53, name: 'DARK_BLUE' },
    { color: 0x7e2553, name: 'DARK_PURPLE' },
    { color: 0x008751, name: 'DARK_GREEN' },
    { color: 0xab5236, name: 'BROWN' },
    { color: 0x5f574f, name: 'DARK_GREY' },
    { color: 0xc2c3c7, name: 'LIGHT_GREY' },
    { color: 0xfff1e8, name: 'WHITE' },
    { color: 0xff004d, name: 'RED' },
    { color: 0xffa300, name: 'ORANGE' },
    { color: 0xffec27, name: 'YELLOW' },
    { color: 0x00e436, name: 'GREEN' },
    { color: 0x29adff, name: 'BLUE' },
    { color: 0x83769c, name: 'LAVENDER' },
    { color: 0xff77a8, name: 'PINK' },
    { color: 0xffccaa, name: 'LIGHT_PEACH' }
];

// Copied from Sameboy
const GAMEBOY_SHADES = [
      0,   6,  12,  20,  28,  36,  45,  56,
     66,  76,  88, 100, 113, 125, 137, 149,
    161, 172, 182, 192, 202, 210, 218, 225,
    232, 238, 243, 247, 250, 252, 254, 255
];

function getGameboyShade(color) {
    const shades = GAMEBOY_SHADES.map((shade, index) => ({
        index,
        dist: Math.abs(color - shade)
    })).sort((a, b) => a.dist - b.dist);
    return shades[0].index;
}

for (const { name, color } of PICO_PALETTE) {
    const r = getGameboyShade((color >> 16) & 0xff);
    const g = getGameboyShade((color >>  8) & 0xff);
    const b = getGameboyShade((color >>  0) & 0xff);
    const gameboy = (r << 0) | (g << 5) | (b << 10);
    console.log(`def PICO_${name} equ $${gameboy.toString(16).padStart(4, '0')}`);
}
