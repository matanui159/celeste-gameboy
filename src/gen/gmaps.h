#ifndef GEN_MAPS_H_
#define GEN_MAPS_H_

#define GAME_MAP_SIZE 16
#define GAME_MAP_TILES (GAME_MAP_SIZE * GAME_MAP_SIZE)
#define GAME_MAPS 32

extern const unsigned char game_maps[GAME_MAPS * GAME_MAP_TILES];

#endif
