import { promises as fs, createReadStream } from 'fs';
import { PNG } from 'pngjs';

function decodeImage(path) {
    return new Promise((resolve, reject) => {
        const image = new PNG();
        createReadStream(path).pipe(image)
            .on('parsed', () => resolve(image))
            .on('error', error => reject(error));
    });
}

const image = await decodeImage('celeste.p8.png');
const memory = Buffer.alloc(0x8000);
for (let i = 0; i < memory.length; i += 1) {
    const r = image.data.readUInt8(i * 4 + 0) & 0x3;
    const g = image.data.readUInt8(i * 4 + 1) & 0x3;
    const b = image.data.readUInt8(i * 4 + 2) & 0x3;
    const a = image.data.readUInt8(i * 4 + 3) & 0x3;
    memory.writeUInt8((a << 6) | (r << 4) | (g << 2) | (b << 0), i);
}

const LUA_TABLE = '\n 0123456789abcdefghijklmnopqrstuvwxyz!#%(){}[]<>+=/*:;.,~_';
let lua = '';
const luaSize = memory.readUInt16BE(0x4304);
let memoryOffset = 0x4308;
while (lua.length < luaSize) {
    const byte = memory.readUInt8(memoryOffset++);
    if (byte === 0x00) {
        lua += String.fromCharCode(memory.readUInt8(memoryOffset++));
    } else if (byte < 0x3c) {
        lua += LUA_TABLE[byte - 1];
    } else {
        const next = memory.readUInt8(memoryOffset++);
        const offset = (byte - 0x3c) * 16 + (next & 0xf);
        const length = (next >> 4) + 2;
        const start = lua.length - offset;
        lua += lua.slice(start, start + length);
    }
}
await fs.writeFile('celeste.lua', lua);

const GD = [0,0,0,0,0,1,0,3,0,0,0,0,2,0,0,0];
const SP = [0,0,0,0,0,1,2,3,0,0,0,0,0,0,0,0];
const FF = [0,1,0,0,2,0,0,0,0,3,0,0,0,0,0,0];
const SG = [0,0,0,0,2,1,0,0,0,3,0,0,0,0,0,0];
const PL = [0,0,0,1,0,0,0,2,3,0,0,0,0,0,0,2];
const __ = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
const SPRITES = [
    GD,PL,PL,PL,PL,PL,PL,PL,__,__,__,__,__,__,__,__,
    GD,SP,SG,SG,__,__,__,FF,FF,FF,__,SP,__,__,__,__,
    GD,GD,GD,GD,GD,GD,GD,GD,GD,GD,GD,SP,__,__,__,__,
    GD,GD,GD,GD,GD,GD,GD,GD,GD,GD,GD,SP,__,__,__,__,
    GD,GD,GD,GD,GD,GD,__,__,GD,__,__,__,__,__,__,__,
    GD,GD,GD,GD,GD,GD,__,__,GD,__,__,__,__,__,__,__,
    __,__,GD,GD,GD,GD,__,GD,GD,__,__,__,__,__,__,__,
    __,__,GD,GD,GD,GD,__,__,__,__,__,__,__,__,__,__,
];

const asm = await fs.open('celeste.asm', 'w');
await asm.write('section "celeste_rom", romx\n');
await asm.write('celeste_sprites::\n');
for (let i = 0; i < SPRITES.length; i += 1) {
    const sprite = SPRITES[i];
    const spriteX = i % 16;
    const spriteY = Math.floor(i / 16);
    let memoryOffset = spriteY * 512 + spriteX * 4;
    await asm.write(`\n    ; #${i} (${spriteX}, ${spriteY})\n`);
    for (let y = 0; y < 8; y += 1) {
        await asm.write('    dw `');
        for (let x = 0; x < 4; x += 1) {
            const byte = memory.readUInt8(memoryOffset + x);
            await asm.write(`${sprite[byte & 0xf]}${sprite[byte >> 4]}`);
        }
        memoryOffset += 64;
        await asm.write('\n');
    }
}
await asm.write('.end::\n');
await asm.close();
