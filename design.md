# Celeste Gameboy Design Notes
This is just going to be a mess of notes. I may in the future clean this up properly and make it more presentable (TODO) but for the time being I am just chucking whatever in wherever. 

## Types of objects in Celeste
These notes are based on the Lua source code extracted from the PICO-8 cartridge. Notably, I wanted to understand and somewhat organise the following information about all the interactable, "live" objects in the game:
- If it is better as a sprite or a tile. If it is better as a tile, could it still be a sprite? What challenges occur if it is forced to be a sprite?
- What is the maximum count of this type of object in the entire game (all the maps)?
- What internal state does it keep?
- What timers does it have? How often does it change its tile/graphics? What other/unique actions does it perform?
- Are there any special considerations for rendering?
- Does the player interact with it and how?
- Does it contribute to physics? Does it have physics on itself? Can it collide with other objects? What is the collision box like?

### `player` and `player_spawn`
This one is pretty simple. It is obviously better as a sprite and there is only one player throughout the entire game. It has alot of internal state but being that there is only one player that state can easily be accounted for. The player hair rendering might be a bit complex, and we also have to be some palette swapping but that can all be late-dev changes where we can see if we can fit it in given the resources available.

Most of the physics code seems to be only used for the player so it might be possible to implement the physics only for the player. Along with this it seems that most objects collide with the player and not with each other so instead of storing or passing through hitboxes, it might be possible to compare an objects hitbox to a hardcoded player hitbox.

`player_spawn` is just a special object for the start of the level to show the jump anaimation and landing before being swapped out for an actual player object.

### `spring`
This is likely better as a tile due to lack of movement. It might be possible to force as a sprite but would be difficult detecting "fall floors" (see below) underneath it. Only internal state it keeps is timers for animation, hiding (when above a fall floor) and reappearing. The later two might be controllable from the fall floor itself (on disappear, remove spring. on reappear add back spring). Doesn't require any special or unique update/render considerations and could entirely be implemented with timers and collision callbacks.

It does interact with the player and is treated as a standard 8x8 tile for the purposes of collision. Does not have any physics itself and while technically it can "collide" with the fall floor below it, that is only to check for its existence, which can be implemented in other ways.

There are a maximum of 3 springs in the game.

### `balloon`
This is the entity that recharges the dashes. In the full release of the game this got replaced with green gems.

This has to be a sprite since it slowly moves up to 2 pixels up and down in a sine wave. This will require constant updating and rerenders, but as a sprite that is easy to implement. It does use a singular timer (for respawn) and otherwise only keeps a start position and sin-wave offset as state. It does not have it's own physics but has a hitbox with a 1px padding around it which it uses for detecting the player.

For rendering it will have to take up two sprites due to the string underneath it. This may end up getting implemented as two seperate objects where the "string" object just positions itself underneath the balloon during the update. 

There are a maximum of 6 balloons in the game.

### `fall_floor`
This is the special blocks that break when you step on them.

### `smoke`
These usually seem to be rendered ontop of other sprites. Despite this never being mentioned specifically in the code, objects are usually rendered in spawn order so objects spawned later (eg. smoke) render ontop (there are a few exceptions to this). On the gameboy color (DMG doesn't have much control over this) it is possible to specify render priority (what renders on top) via the position in the OAM, where the first sprite is rendered ontop. Smoke rendering can be implemented using either by keeping the first part of the OAM free specifically for particles, or if there is an allocation scheme, allocating from the end of the OAM to the start (in reverse order).

### `fruit` and `fly_fruit`
Yet again both of these have to be a sprite due to slight sine-wave movements. The fruit yet again has a start position and offset, while the flying fruit additionally has a vertical speed and "is flying" state. The flying strawberry will require three sprites to render. Due to palette limitations the center part will not have the start of the wings next to it and will share the same sprite as the non-flying strawberry. The wing sprites may need to be modified to include these parts (they seem to only currently be 7px wide).

The flying strawberry does technically use the physics engine via modifying its own speed, but does no collisions and isn't solid so practically only moves by the current speed.

There is always only a maximum of one strawberry per level. When the strawberry is collected it is marked as collected in an array of the levels (if the level has a strawberry) so that all strawberry-related objects (these two, fake walls, keys and chests) don't spawn again when the map is reloaded. Whether an object spawns or not after strawberry collection is marked with a special `if_not_fruit` flag in the object type. To save on memory it might be better to either keep a flag to see if the strawberry has been collected in the current level, or alternatively a map ID for the latest level that the strawberry has been collected so the flag doesn't have to be cleared.

### `lifeup`
This is the "1000" text that pops up when the player collects a strawberry, it has nothing to do with lives.

Internally it keeps a timer, flash animation and vertical speed as state. The timer can be implemented as part of a generic timer API and the speed is constant so can be hard coded during updates. It may be possible to reuse the memory from the strawberries as well (if specific memory has given to them).

Due to spawning after the collection of a strawberry, there can only ever be one of these for a short amount of time. Likely can replace the fruit sprite in the OAM (or one of the sprites, if its a flying fruit with 3 sprites).
