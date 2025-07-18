# wfc = Wave Function Collapse Algorithm
# https://github.com/mxgmn/WaveFunctionCollapse

extends Node

# O - Ocean
# M - Mountain
# F - Forest
# S - Sand

enum Compass { N = 0, S = 1, W = 2, E = 3 }

const DIRECTIONS: Dictionary[Compass, Vector2i] = {
	Compass.N: Vector2i(0, -1),
	Compass.S: Vector2i(0, 1),
	Compass.W: Vector2i(-1, 0),
	Compass.E: Vector2i(1, 0),
}

class BannedTile:
	var cell_position: Vector2i
	var tile_index: int
	
	func _init(_cell_position: Vector2i, _tile_index: int):
		cell_position = _cell_position
		tile_index = _tile_index

class PossibleNeighborTiles:
	var direction: Compass
	# replace with actual tiles later on
	var tiles: Array[String]
	
	func _init(_direction: Compass, _tiles: Array[String]):
		direction = _direction
		tiles = []
		tiles.append_array(_tiles)

class PossibleNeighborTilesList:
	var possible_tiles: Array[PossibleNeighborTiles]
	
	func _init(_possible_tiles: Array[PossibleNeighborTiles]):
		possible_tiles = []
		possible_tiles.append_array(_possible_tiles)

class PossibleTiles:
	# switch to actual tiles later on
	var tiles: Array[String]
	
	func _init(_tiles: Array[String]):
		tiles = []
		tiles.append_array(_tiles)

# represents the possible tile selections the algorithm can pick from
# gets collapsed down to 1 tile per cell once algorithm finishes
# first index - row position (y position)
# second index - col position (x position)
# value - string representing tile for now (will swap out with actual tiles later on)
var wave_state: Array[Array]
var width: int
var height: int
var tiles_count: int

# end of array represents the latest banned tile
# beginning of array represents oldest banned tile
var banned_tiles_stack: Array[BannedTile]
# keeps track of where the latest banned tile is
var stack_size: int

# a lookup table to determine which neighboring tiles are valid to pick 
# when a tile at a given position is chosen
# key - cell index on map
# value - list of possible tiles to pick from where each entry represents a neighboring tile
var possible_neighboring_tiles_table: Dictionary[Vector2i, PossibleNeighborTiles]

# this represents how many tile options are left for a given cell
# 2D array of PossibleTiles
# first index represents row (y)
# second index represents col (x)
var possible_tile_choices: Array[Array]

### Weights - used to decide which tile to pick for a given cell
### these are all 2d arrays containing floats
var weights: Array[Array]
var log_weights: Array[Array]
# represents the current pick distribution rate when selecting a tile for a given cell
var distribution: Array[Array]

var sum_of_weights: float
var sum_of_log_weights: float
var starting_entropy: float

### these are all 2d arrays containing floats
var sums_of_weights: Array[Array]
var sums_of_log_weights: Array[Array]



func init():
	pass

func clear():
	pass

func pick_unobserved_cell():
	pass
	
func observe_cell():
	pass
	
func propagate_constraints() -> bool:
	return false
	
func ban_tile():
	pass
	
func run() -> bool:
	init()
	clear()
	
	var is_puzzle_solved: bool = false
	# while you still have a cell to pick a tile from the grid, continue the loop
	# otherwise stop the loop
	while true:
		var cell_coords: Vector2i = pick_unobserved_cell()
		var is_puzzle_incomplete: bool = cell_coords.x >= 0 and cell_coords.y >= 0
		if is_puzzle_incomplete:
			observe_cell()
			var have_tile_options_from_any_cell = propagate_constraints()
			if !have_tile_options_from_any_cell:
				is_puzzle_solved = false
				break
		else:
			# WFC algorithm completed solving the grid map layout
			is_puzzle_solved = true
			break
	
	return is_puzzle_solved
