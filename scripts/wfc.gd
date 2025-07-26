# wfc = Wave Function Collapse Algorithm
# https://github.com/mxgmn/WaveFunctionCollapse

extends Node

@export var button: Button
@export var map: TileMapLayer

@export var width: int = 10
@export var height: int = 10
@export var tiles_count: int

#region TILES
# alternative IDs will be used for picking out which rotated tile to use
# these coordinates are hardcoded atlas coordinates from the maze_tileset.tres resource
const GRASS_TILE = Vector2i(2,2)
const STONE_TILE = Vector2i(2,5)
const WATER_TILE = Vector2i(12,5)
const DIRT_TILE = Vector2i(16, 3)

const GRASS_TL_CORNER = Vector2i(0,0)
const GRASS_BL_CORNER = Vector2i(0,4)
const GRASS_TR_CORNER = Vector2i(5,0)
const GRASS_BR_CORNER = Vector2i(5,4)
const GRASS_CENTER = Vector2i(4,2)
const GRASS_TOP = Vector2i(3,0)
const GRASS_BOT = Vector2i(3,4)
const GRASS_LEFT = Vector2i(0,2)
const GRASS_RIGHT = Vector2i(5,2)

const GRASSWATER_TOP = Vector2i(2,1)
const GRASSWATER_BOT = Vector2i(2,3)
const GRASSWATER_LEFT = Vector2i(1,2)
const GRASSWATER_RIGHT = Vector2i(3,2)
const GRASSWATER_TL = Vector2i(1,1)
const GRASSWATER_TR = Vector2i(3,1)
const GRASSWATER_BL = Vector2i(1,3)
const GRASSWATER_BR = Vector2i(3,3)

const WATEREDGE_TL = Vector2i(11,4)
const WATEREDGE_TC = Vector2i(12,4)
const WATEREDGE_TR = Vector2i(13,4)
const WATEREDGE_LC = Vector2i(11,5)
const WATEREDGE_RC = Vector2i(13,5)
const WATEREDGE_CC = Vector2i(12,5)
const WATEREDGE_BL = Vector2i(11,6)
const WATEREDGE_BC = Vector2i(12,6)
const WATEREDGE_BR = Vector2i(13,6)

const EMPTY_TILE = Vector2i(22,7)
const ROCK_TILE = Vector2i(9,7)
#endregion

const TILES: Array[Vector2i] = [
	GRASS_TL_CORNER,
	GRASS_BL_CORNER,
	GRASS_TR_CORNER,
	GRASS_BR_CORNER,
	GRASS_CENTER,
	GRASS_TOP,
	GRASS_BOT,
	GRASS_LEFT,
	GRASS_RIGHT,

	GRASSWATER_TOP,
	GRASSWATER_BOT,
	GRASSWATER_LEFT,
	GRASSWATER_RIGHT,
	GRASSWATER_TL,
	GRASSWATER_TR,
	GRASSWATER_BL,
	GRASSWATER_BR,

	WATEREDGE_TL,
	WATEREDGE_TC,
	WATEREDGE_TR,
	WATEREDGE_LC,
	WATEREDGE_RC,
	WATEREDGE_CC,
	WATEREDGE_BL,
	WATEREDGE_BC,
	WATEREDGE_BR,
	
	EMPTY_TILE,
	# STONE_TILE,
]

## Vector2i represents the atlas coordinates of tiles found in the map's TileSet's TileSetSource Resource
#const TILES: Array[Vector2i] = [
	#GRASS_TILE, STONE_TILE, WATER_TILE, DIRT_TILE
#]
#
## used to determine which tiles fit together like a puzzle piece
## this can be thought of as a rule set of which tiles can be connected together
## key - tile's atlas coordinates
## value - list of Vector2i atlas coordinates of tiles that are compatible with this tile
#var compatible_tiles: Dictionary[Vector2i, Array] = {
	#WATER_TILE: [WATER_TILE, DIRT_TILE],
	#DIRT_TILE: [DIRT_TILE, WATER_TILE, STONE_TILE, GRASS_TILE],
	#STONE_TILE: [STONE_TILE, GRASS_TILE, DIRT_TILE],
	#GRASS_TILE: [GRASS_TILE, STONE_TILE, DIRT_TILE]
#}

enum Compass { N = 0, S = 1, W = 2, E = 3 }

const DIRECTIONS: Dictionary[Compass, Vector2i] = {
	Compass.N: Vector2i(0, -1),
	Compass.S: Vector2i(0, 1),
	Compass.W: Vector2i(-1, 0),
	Compass.E: Vector2i(1, 0),
}

const DIRECTIONS_COMPASS: Dictionary[Vector2i, Compass] = {
	Vector2i(0, -1): Compass.N,
	Vector2i(0, 1): Compass.S,
	Vector2i(-1, 0): Compass.W,
	Vector2i(1, 0): Compass.E,
}

# TODO: create a tool that lets me pick this out visually....
# key: Vector2i - represents atlas coordinates of tiles found
# value: Dictionary
# inner key: represents direction in which a tile can be placed
# inner value: Array of Vector2i atlas tile coordinates of compatible tiles for the given direction 
var compatible_tiles: Dictionary[Vector2i, Dictionary] = {
	GRASS_TL_CORNER: {
		Compass.N: [EMPTY_TILE],
		Compass.S: [GRASS_LEFT],
		Compass.W: [EMPTY_TILE],
		Compass.E: [GRASS_TOP],
	},
	GRASS_BL_CORNER: {
		Compass.N: [GRASS_LEFT],
		Compass.S: [EMPTY_TILE],
		Compass.W: [EMPTY_TILE],
		Compass.E: [GRASS_BOT],
	},
	GRASS_TR_CORNER: {
		Compass.N: [EMPTY_TILE],
		Compass.S: [GRASS_RIGHT],
		Compass.W: [GRASS_TOP],
		Compass.E: [EMPTY_TILE],
	},
	GRASS_BR_CORNER: {
		Compass.N: [GRASS_RIGHT],
		Compass.S: [EMPTY_TILE],
		Compass.W: [GRASS_BOT],
		Compass.E: [EMPTY_TILE],
	},
	GRASS_CENTER: {
		Compass.N: [GRASS_TOP, GRASS_CENTER, GRASSWATER_BL, GRASSWATER_BR],
		Compass.S: [GRASS_BOT, GRASS_CENTER, GRASSWATER_TL, GRASSWATER_TR],
		Compass.W: [GRASS_LEFT, GRASS_CENTER, GRASSWATER_TR, GRASSWATER_BR],
		Compass.E: [GRASS_RIGHT, GRASS_CENTER, GRASSWATER_TL, GRASSWATER_BL],
	},
	GRASS_TOP: {
		Compass.N: [EMPTY_TILE],
		Compass.S: [GRASS_CENTER, GRASSWATER_TL, GRASSWATER_TR, GRASSWATER_TOP],
		Compass.W: [GRASS_TOP, GRASS_TL_CORNER],
		Compass.E: [GRASS_TOP, GRASS_TR_CORNER],
	},
	GRASS_BOT: {
		Compass.N: [GRASS_CENTER, GRASSWATER_BL, GRASSWATER_BR, GRASSWATER_BOT],
		Compass.S: [EMPTY_TILE],
		Compass.W: [GRASS_BOT, GRASS_BL_CORNER],
		Compass.E: [GRASS_BOT, GRASS_BR_CORNER],
	},
	GRASS_LEFT: {
		Compass.N: [GRASS_LEFT, GRASS_TL_CORNER],
		Compass.S: [GRASS_LEFT, GRASS_BL_CORNER],
		Compass.W: [EMPTY_TILE],
		Compass.E: [GRASS_CENTER, GRASSWATER_BL, GRASSWATER_TL],
	},
	GRASS_RIGHT: {
		Compass.N: [GRASS_RIGHT, GRASS_TR_CORNER],
		Compass.S: [GRASS_RIGHT, GRASS_BR_CORNER],
		Compass.W: [GRASS_CENTER, GRASSWATER_BR, GRASSWATER_TR],
		Compass.E: [EMPTY_TILE],
	},
	
	GRASSWATER_TOP: {
		Compass.N: [GRASS_CENTER, GRASS_TOP],
		Compass.S: [WATEREDGE_TC],
		Compass.W: [GRASSWATER_TOP, GRASSWATER_TL],
		Compass.E: [GRASSWATER_TOP, GRASSWATER_TR],
	},
	GRASSWATER_BOT: {
		Compass.N: [WATEREDGE_BC],
		Compass.S: [GRASS_CENTER, GRASS_BOT],
		Compass.W: [GRASSWATER_BOT, GRASSWATER_BL],
		Compass.E: [GRASSWATER_BOT, GRASSWATER_BR],
	},
	GRASSWATER_LEFT: {
		Compass.N: [GRASSWATER_LEFT, GRASSWATER_TL],
		Compass.S: [GRASSWATER_LEFT, GRASSWATER_BL],
		Compass.W: [GRASS_CENTER, GRASS_LEFT],
		Compass.E: [WATEREDGE_LC],
	},
	GRASSWATER_RIGHT: {
		Compass.N: [GRASSWATER_RIGHT, GRASSWATER_TR],
		Compass.S: [GRASSWATER_RIGHT, GRASSWATER_BR],
		Compass.W: [WATEREDGE_RC],
		Compass.E: [GRASS_CENTER, GRASS_RIGHT],
	},
	GRASSWATER_TL: {
		Compass.N: [GRASS_CENTER, GRASS_TOP],
		Compass.S: [GRASSWATER_LEFT],
		Compass.W: [GRASS_CENTER, GRASS_LEFT],
		Compass.E: [GRASSWATER_TOP],
	},
	GRASSWATER_TR: {
		Compass.N: [GRASS_CENTER, GRASS_TOP],
		Compass.S: [GRASSWATER_RIGHT],
		Compass.W: [GRASSWATER_TOP],
		Compass.E: [GRASS_CENTER, GRASS_RIGHT],
	},
	GRASSWATER_BL: {
		Compass.N: [GRASSWATER_LEFT],
		Compass.S: [GRASS_CENTER, GRASS_BOT],
		Compass.W: [GRASS_CENTER, GRASS_LEFT],
		Compass.E: [GRASSWATER_BOT],
	},
	GRASSWATER_BR: {
		Compass.N: [GRASSWATER_RIGHT],
		Compass.S: [GRASS_CENTER, GRASS_BOT],
		Compass.W: [GRASSWATER_BOT],
		Compass.E: [GRASS_CENTER, GRASS_RIGHT],
	},
	
	WATEREDGE_TL: {
		Compass.N: [GRASSWATER_TOP],
		Compass.S: [WATEREDGE_LC],
		Compass.W: [GRASSWATER_LEFT],
		Compass.E: [WATEREDGE_TC, WATEREDGE_TR],
	},
	WATEREDGE_TC: {
		Compass.N: [GRASSWATER_TOP],
		Compass.S: [WATEREDGE_CC, WATEREDGE_BC],
		Compass.W: [WATEREDGE_TC, WATEREDGE_TL],
		Compass.E: [WATEREDGE_TC, WATEREDGE_TR],
	},
	WATEREDGE_TR: {
		Compass.N: [GRASSWATER_TOP],
		Compass.S: [WATEREDGE_RC],
		Compass.W: [WATEREDGE_TC],
		Compass.E: [GRASSWATER_RIGHT],
	},
	WATEREDGE_LC: {
		Compass.N: [WATEREDGE_LC, WATEREDGE_TL],
		Compass.S: [WATEREDGE_LC, WATEREDGE_BL],
		Compass.W: [GRASSWATER_LEFT],
		Compass.E: [WATEREDGE_CC],
	},
	WATEREDGE_RC: {
		Compass.N: [WATEREDGE_RC, WATEREDGE_TR],
		Compass.S: [WATEREDGE_RC, WATEREDGE_BR],
		Compass.W: [WATEREDGE_CC],
		Compass.E: [GRASSWATER_RIGHT],
	},
	WATEREDGE_CC: {
		Compass.N: [WATEREDGE_CC, WATEREDGE_TC],
		Compass.S: [WATEREDGE_CC, WATEREDGE_BC],
		Compass.W: [WATEREDGE_CC, WATEREDGE_LC],
		Compass.E: [WATEREDGE_CC, WATEREDGE_RC],
	},
	WATEREDGE_BL: {
		Compass.N: [WATEREDGE_LC],
		Compass.S: [GRASSWATER_BOT],
		Compass.W: [GRASSWATER_LEFT],
		Compass.E: [WATEREDGE_BC, WATEREDGE_BR],
	},
	WATEREDGE_BC: {
		Compass.N: [WATEREDGE_CC],
		Compass.S: [GRASSWATER_BOT],
		Compass.W: [WATEREDGE_BC, WATEREDGE_BL],
		Compass.E: [WATEREDGE_BC, WATEREDGE_BR],
	},
	WATEREDGE_BR: {
		Compass.N: [WATEREDGE_RC],
		Compass.S: [GRASSWATER_BOT],
		Compass.W: [WATEREDGE_BC],
		Compass.E: [GRASSWATER_RIGHT],
	},
	
	EMPTY_TILE: {
		Compass.N: [GRASS_BL_CORNER, GRASS_BOT, GRASS_BR_CORNER],
		Compass.S: [GRASS_TL_CORNER, GRASS_TOP, GRASS_TR_CORNER],
		Compass.W: [GRASS_RIGHT, GRASS_TR_CORNER, GRASS_BR_CORNER, EMPTY_TILE],
		Compass.E: [GRASS_LEFT, GRASS_TL_CORNER, GRASS_BL_CORNER, EMPTY_TILE],
	},
	
	STONE_TILE: {
		Compass.N: [STONE_TILE, GRASS_BOT, EMPTY_TILE],
		Compass.S: [STONE_TILE, GRASS_TOP, EMPTY_TILE],
		Compass.W: [STONE_TILE, GRASS_LEFT, EMPTY_TILE],
		Compass.E: [STONE_TILE, GRASS_RIGHT, EMPTY_TILE],
	}
}

class BannedTile:
	var cell_position: Vector2i
	var tile_index: int
	
	func _init(_cell_position: Vector2i, _tile_index: int):
		cell_position = _cell_position
		tile_index = _tile_index

class PossibleTiles:
	var tiles: Array[Vector2i]
	
	func _init(_tiles: Array[Vector2i]):
		tiles = []
		tiles.append_array(_tiles)
	
	func size() -> int:
		return len(tiles)
		
	func get_tile(index: int) -> Vector2i:
		assert(index >= 0 and index < len(tiles))
		return tiles[index]
	
	func has_tile(tile: Vector2i) -> bool:
		return tile in tiles
	
	func remove(tile: Vector2i) -> bool:
		if tile not in tiles:
			return false
			
		var remove_tile_index: int = -1
		for i in range(len(tiles)):
			if tiles[i] == tile:
				remove_tile_index = i
				break
		
		tiles.remove_at(remove_tile_index)
		return true

# this represents how many tile options are left for a given cell
# gets collapsed down to 1 tile per cell once algorithm finishes
# 2D array of PossibleTiles
# first index represents row (y)
# second index represents col (x)
var possible_tile_choices: Array[Array]

# end of array represents the latest banned tile
# beginning of array represents oldest banned tile
var banned_tiles_stack: Array[BannedTile] = []


### Weights - used to decide which tile to pick for a given cell
const WEIGHTS_TABLE: Dictionary[Vector2i, float] = {
	#GRASS_TILE: 2.0,
	#STONE_TILE: 2.0,
	#WATER_TILE: 2.0,
	#DIRT_TILE: 2.0,
	
	GRASS_TL_CORNER: 4.0,
	GRASS_BL_CORNER: 4.0,
	GRASS_TR_CORNER: 4.0,
	GRASS_BR_CORNER: 4.0,
	GRASS_CENTER: 32.0,
	GRASS_TOP: 8.0,
	GRASS_BOT: 8.0,
	GRASS_LEFT: 8.0,
	GRASS_RIGHT: 8.0,
	
	GRASSWATER_TOP: 4.0,
	GRASSWATER_BOT: 4.0,
	GRASSWATER_LEFT: 4.0,
	GRASSWATER_RIGHT: 4.0,
	GRASSWATER_TL: 4.0,
	GRASSWATER_TR: 4.0,
	GRASSWATER_BL: 4.0,
	GRASSWATER_BR: 4.0,
	
	WATEREDGE_TL:  8.0,
	WATEREDGE_TC:  8.0,
	WATEREDGE_TR:  8.0,
	WATEREDGE_LC:  8.0,
	WATEREDGE_RC:  8.0,
	WATEREDGE_CC:  8.0,
	WATEREDGE_BL:  8.0,
	WATEREDGE_BC:  8.0,
	WATEREDGE_BR:  8.0,
	
	EMPTY_TILE: 2.0,
	#STONE_TILE: 2.0,
}


### these are all arrays containing floats
### index is tile index
var weights: Array[float]
var log_weights: Array[float]
# represents the current pick distribution rate when selecting a tile for a given cell
var distribution: Array[float]

var sum_of_weights: float = 0.0
var sum_of_log_weights: float = 0.0
var starting_entropy: float = 0.0

### these are all 2d arrays containing floats
var sums_of_weights: Array[Array]
var sums_of_log_weights: Array[Array]
var entropies: Array[Array]

var visited_cells: Dictionary[Vector2i, bool] = {}

func init():
	possible_tile_choices.resize(height)
	sums_of_weights.resize(height)
	sums_of_log_weights.resize(height)
	entropies.resize(height)
	
	for row in range(height):
		possible_tile_choices[row].resize(width)
		sums_of_weights[row].resize(width)
		sums_of_log_weights[row].resize(width)
		entropies[row].resize(width)
		for col in range(width):
			possible_tile_choices[row][col] = PossibleTiles.new(TILES)
			sums_of_weights[row][col] = 0.0
			sums_of_log_weights[row][col] = 0.0
			entropies[row][col] = 0.0
	
	weights.resize(tiles_count)
	log_weights.resize(tiles_count)
	
	# compute weights using Shannon Entropy
	# Source: https://github.com/mxgmn/WaveFunctionCollapse/blob/master/Model.cs
	# starts at line 55 of source code link
	assert(tiles_count == len(WEIGHTS_TABLE))
	var t: int = 0
	var custom_weights = WEIGHTS_TABLE.values()
	while t < tiles_count:
		weights[t] = float(custom_weights[t])
		log_weights[t] = weights[t] * log(weights[t])
		sum_of_weights += weights[t]
		sum_of_log_weights += log_weights[t]
		t += 1

	assert(sum_of_weights > 0)
	starting_entropy = log(sum_of_weights) - (sum_of_log_weights / sum_of_weights)

func clear():
	visited_cells.clear()
	
	for row in range(height):
		for col in range(width):
			sums_of_weights[row][col] = sum_of_weights
			sums_of_log_weights[row][col] = sum_of_log_weights
			entropies[row][col] = starting_entropy

# pick a cell with the lowest entropy
# here entropy is a heuristic which means cells with more tile choices to choose from
# than other cells have higher entropies than those that have fewer choices.
# Lower entropy means that cells with less tile choices to choose from than
# other cells have lower entropy than those that have more choices to pick from 
# returns a Vector2i (x = col, y = row)
func pick_unobserved_cell() -> Vector2i:
	
	# start with a big number so that it can pick a cell at the beginning
	var min: float = 10_000
	# if cell stays as -1, -1; it means that all cells have a tile chosen
	var cell = Vector2i(-1, -1)
	
	for row in range(height):
		for col in range(width):
			if visited_cells.has(Vector2i(col, row)):
				continue
				
			var entropy: float = entropies[row][col]
			var tile_choices: int = possible_tile_choices[row][col].size()
			
			# noise is used here because in the first iteration all cells have the same entropy
			# therefore, noise is added as a tiebreaker
			var noise: float = 1E-6 * fmod(randf(), 1.0)
			
			#if tile_choices > 1 and entropy + noise <= min:
			if entropy + noise < min:
				min = entropy + noise
				cell = Vector2i(col, row)
	
	if cell.x != -1 and cell.y != -1:
		visited_cells[cell] = true
	
	#print("cell picked: ", cell)
	return cell

# compute possible tile options based on its neighboring cells for the current grid state
func compute_tile_choices(position: Vector2i) -> PossibleTiles:
	var tile_choices: Array[Vector2i] = []
	var tile_set: Dictionary[Vector2i, bool] = {}
	for direction in DIRECTIONS:
		var neighbor_cell: Vector2i = position + DIRECTIONS[direction]
		if neighbor_cell.x < 0 or neighbor_cell.y < 0 or neighbor_cell.x >= width or neighbor_cell.y >= height:
			continue
		
		# all possible tiles for a neighboring cell
		for tile in possible_tile_choices[neighbor_cell.y][neighbor_cell.x].tiles:
			var opposite_direction: Vector2i = -1 * DIRECTIONS[direction]
			var opp_dir: Compass = DIRECTIONS_COMPASS[opposite_direction]
			var compat_tiles: Array = compatible_tiles[tile][opp_dir]
			for compat_tile in compat_tiles:
				tile_set[compat_tile] = true
		
	for tile in tile_set:
		tile_choices.append(tile)
		
	return PossibleTiles.new(tile_choices)

func observe_cell(cell: Vector2i):
	# assign tile weights for the given cell inputted
	distribution = []
	var current_possible_tiles: PossibleTiles = possible_tile_choices[cell.y][cell.x]
	var possible_tile_choices_count: int = current_possible_tiles.size()
	
	# recompute possibilities if 0 was found from propagation step
	if possible_tile_choices_count == 0:
		possible_tile_choices[cell.y][cell.x] = compute_tile_choices(cell)
		current_possible_tiles = possible_tile_choices[cell.y][cell.x]
		possible_tile_choices_count = current_possible_tiles.size()
	
	for t in range(possible_tile_choices_count):
		var tile_coords: Vector2i = current_possible_tiles.get_tile(t)
		var weight: float = WEIGHTS_TABLE[tile_coords]
		distribution.append(weight)

	
	# pick a random tile to place in the given cell
	var sum: float = 0.0
	for t in range(len(distribution)):
		sum += distribution[t]
	
	# a random percentage of the sum will be used to determine which tiles will be used left in the tiles pool
	var threshold: float = fmod(randf(), 1.0) * sum
	var partial_sum: float = 0.0
	var tile_index: int = 0
	for t in range(len(distribution)):
		partial_sum += distribution[t]
		if partial_sum >= threshold:
			tile_index = t
			break
	
	var picked_tile: Vector2i = current_possible_tiles.get_tile(tile_index)
	# print("picked tile: ", picked_tile)
	
	# ban all tiles that don't match tile_index for the given cell index -- collapse
	for t in range(tiles_count):
		if picked_tile != TILES[t] and current_possible_tiles.has_tile(TILES[t]):
			ban_tile(cell, t)

# returns true if any cell has more than 1 tile to pick from from any cell
# returns false otherwise
func propagate_constraints() -> bool:
	var visited_cells: Dictionary[Vector2i, bool] = {}
	
	while len(banned_tiles_stack) > 0:
		# pick the latest tile banned
		var banned_tile: BannedTile = banned_tiles_stack.pop_back()
		assert(banned_tile != null)
		
		if visited_cells.has(banned_tile.cell_position):
			continue
		
		visited_cells[banned_tile.cell_position] = true
		
		# look at the neighboring tiles relative to the banned_tile's location
		# and see if they have compatible tiles to place
		# if zero tiles are compatible, ban the tile for that neighboring location
		# compatible here means tiles that "fit like a puzzle piece" with what was just placed
		# in the grid.
		# for a tiles spritesheet, the user marks which tiles in the spritesheet are compatible
		# with another in order to make maps that look interesting and not out of place
		
		# Neighbors of Neighbors
		# Step 1: form a UnionSet of all possible tile choices for each neighbor cell
		# Step 2 (bitwise application):
		# Compatible Tiles Mask = (All Tiles from Tile Set AND UnionSet)
		# - a bit set as 0 tells us this tile is incompatible (ban the tile for this position)
		# - a bit set as 1 tells us this tile is compatible (keep the tile for this position)
		
		# Edge Cases
		# if a tile is picked for a given cell, don't visit it
		# if there are 0 tile options for a given cell, don't visit it 
		# if a cell is out of bounds, don't visit it
		
		# this means no more choices for this cell is possible resulting in an incomplete puzzle
		if possible_tile_choices[banned_tile.cell_position.y][banned_tile.cell_position.x].size() <= 0:
			var curr_possible_choices: PossibleTiles = compute_tile_choices(banned_tile.cell_position)
			possible_tile_choices[banned_tile.cell_position.y][banned_tile.cell_position.x] = curr_possible_choices
			if curr_possible_choices.size() <= 0:
				return false
		
		# after the first cell propagation... neighbor of neighbors can have multiple tile choices to pick from
		# var tiles_union_set: Dictionary[Vector2i, bool] = {}
		# inner dictionary
		# inner key - Vector2i representing atlas tile texture coordinate
		# inner value - boolean representing whether or not tile exists in the union set
		var tiles_union_set: Dictionary[Compass, Dictionary] = {}
		for possible_tile in possible_tile_choices[banned_tile.cell_position.y][banned_tile.cell_position.x].tiles:
			# var compat_tiles: Array = compatible_tiles[picked_tile]
			var compat_tiles_dirs: Dictionary = compatible_tiles[possible_tile]
			for dir in compat_tiles_dirs:
				tiles_union_set[dir] = {}
				var compat_tiles: Array = compat_tiles_dirs[dir]
				for compat_tile in compat_tiles:
					tiles_union_set[dir][compat_tile] = true
		
		var length: int = len(tiles_union_set)
		# ????
		if length == 0:
			return false
		# assert(length > 0)
		
		# key = compass direction
		# value = array of eliminated tile indices - Array[int]
		var eliminated_tile_indices: Dictionary[Compass, Array] = {
			Compass.N: [],
			Compass.S: [],
			Compass.W: [],
			Compass.E: [],
		} 
		
		var cardinal_directions: Array = DIRECTIONS.keys()
		for t in range(len(TILES)):
			var tile: Vector2i = TILES[t]
			for dir in cardinal_directions:
				if tile not in tiles_union_set[dir]:
					eliminated_tile_indices[dir].append(t)
		
		for direction in DIRECTIONS:
			var delta_dir: Vector2i = DIRECTIONS[direction]
			var neighbor_position: Vector2i = banned_tile.cell_position + delta_dir
			
			# skip if out of bounds
			if neighbor_position.x >= width or neighbor_position.x < 0 or neighbor_position.y >= height or neighbor_position.y < 0:
				continue
			
			# skip if tile picked for location OR if 0 tile choices are available for this location
			var choices_left: int = possible_tile_choices[neighbor_position.y][neighbor_position.x].size()
			if choices_left <= 1:
				continue
				
			for t in eliminated_tile_indices[direction]:
				if possible_tile_choices[neighbor_position.y][neighbor_position.x].has_tile(TILES[t]):
					ban_tile(neighbor_position, t)
		
	# count number of choices left to make per cell
	var total_choices_left: int = 0
	for row in range(height):
		for col in range(width):
			var choices_left: int = possible_tile_choices[row][col].size()
			total_choices_left += choices_left
	
	return total_choices_left > 0
	
func ban_tile(cell_position: Vector2i, tile_index: int):
	assert(tile_index >= 0 and tile_index < len(TILES))
	var tile: Vector2i = TILES[tile_index]
	possible_tile_choices[cell_position.y][cell_position.x].remove(tile)
	
	banned_tiles_stack.append(BannedTile.new(cell_position, tile_index))
	
	# update weights
	sums_of_weights[cell_position.y][cell_position.x] -= weights[tile_index]
	sums_of_log_weights[cell_position.y][cell_position.x] -= log_weights[tile_index]
	
	# recompute shannon entropy
	var sums: float = sums_of_weights[cell_position.y][cell_position.x]
	entropies[cell_position.y][cell_position.x] = 0 if sums == 0 else log(sums) - sums_of_log_weights[cell_position.y][cell_position.x] / sums 

func print_puzzle():
	print("------------------------PUZZLE-------------------------------")
	for row in range(height):
		var string_row: String = ""
		for col in range(width):
			var choice_count: int = possible_tile_choices[row][col].size()
			if choice_count == 1:
				string_row += "%2.0v " % possible_tile_choices[row][col].get_tile(0)
			else: # many choices are either still left or no valid tiles can be picked
				string_row += ". "
		
		print(string_row)
	print("---------------------------------------------------------------")

func print_grid_state():
	for row in range(height):
		var row_string: String = ""
		for col in range(width):
			var tiles: Array[Vector2i] = possible_tile_choices[row][col].tiles
			row_string +=  "[" + ",".join(tiles) + "]\t"
		print(row_string)
		print("---------------------------------------------------")

func run() -> bool:
	init()
	clear()
	
	#print_grid_state()
	#print("-----------------------------")
	
	var is_puzzle_solved: bool = false
	var is_puzzle_in_progress: bool = true
	var iterations: int = 0
	# while you still have a cell to pick a tile from the grid, continue the loop
	# otherwise stop the loop
	while is_puzzle_in_progress:
		#print("------------BEFORE---------------")
		#print_grid_state()
		#print("---------------------------------")
		
		var cell_coords: Vector2i = pick_unobserved_cell()
		var is_puzzle_incomplete: bool = cell_coords.x >= 0 and cell_coords.y >= 0
		if is_puzzle_incomplete:
			observe_cell(cell_coords)
			var have_tile_options_from_any_cell = propagate_constraints()
			if !have_tile_options_from_any_cell:
				is_puzzle_solved = false
				is_puzzle_in_progress = false
				print("Not solvable")
		else:
			# WFC algorithm completed solving the grid map layout
			is_puzzle_solved = true
			is_puzzle_in_progress = false
			
		iterations += 1
		
		#print("------------AFTER----------------")
		#print_grid_state()
		#print("---------------------------------")
			
			
	#print_puzzle()
	return is_puzzle_solved

func run_wave_function_collapse():
	
	var start_time: int = Time.get_ticks_msec()
	
	map.clear()
	
	var is_successful: bool = run()
	print("is successful? ", is_successful)
	
	place_tiles()
		
	var time_processed: int = Time.get_ticks_msec() - start_time
	print("Time processed in milliseconds: %d" % time_processed)

func place_tiles():
	
	# print_grid_state()
	
	for row in range(height):
		for col in range(width):
			var tile_choices: int = possible_tile_choices[row][col].size()
			var position = Vector2i(col, row)
			var tile_set_source_id: int = 0
			
			# not solvable case
			if tile_choices == 0:
				map.set_cell(position, tile_set_source_id, ROCK_TILE)
			# multiple tiles to pick for this cell
			elif tile_choices > 1:
				const MUSHROOM_TILE = Vector2i(10,7)
				map.set_cell(position, tile_set_source_id, MUSHROOM_TILE)
			# 1 tile to pick for this cell
			else:
				var atlas_coords: Vector2i = possible_tile_choices[row][col].tiles[0]
				map.set_cell(position, tile_set_source_id, atlas_coords)

func _ready():
	tiles_count = len(TILES)
	print(tiles_count)
	button.pressed.connect(run_wave_function_collapse)
