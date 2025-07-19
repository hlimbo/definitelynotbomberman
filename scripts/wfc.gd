# wfc = Wave Function Collapse Algorithm
# https://github.com/mxgmn/WaveFunctionCollapse

extends Node

# goal: have an NxM grid of characters generate a map of characters outputted as console log
# O - Ocean
# M - Mountain
# F - Forest
# S - Sand
const TILES: Array[String] = ["O", "M", "F", "S"]

@onready var button: Button = $my_button

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
		
	func remove(tile: String):
		assert(tile in tiles)
		var remove_tile_index: int = -1
		for i in range(len(tiles)):
			if tiles[i] == tile:
				remove_tile_index = i
				break
		
		tiles.remove_at(remove_tile_index)

# a lookup table to determine which neighboring tiles are valid to pick 
# when a tile at a given position is chosen
# key - cell index on map
# value - list of possible tiles to pick from where each entry represents a neighboring tile
var possible_neighboring_tiles_table: Dictionary[Vector2i, PossibleNeighborTiles]

@export var width: int = 10
@export var height: int = 10
@export var tiles_count: int = 4

# this represents how many tile options are left for a given cell
# gets collapsed down to 1 tile per cell once algorithm finishes
# 2D array of PossibleTiles
# first index represents row (y)
# second index represents col (x)
var possible_tile_choices: Array[Array]
# represents the final tile map output to console log
# 2d Array of Strings
var wave_output: Array[Array]

# end of array represents the latest banned tile
# beginning of array represents oldest banned tile
var banned_tiles_stack: Array[BannedTile] = []
# keeps track of where the latest banned tile is
var stack_size: int


### Weights - used to decide which tile to pick for a given cell
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


func init():
	wave_output.resize(height)
	possible_tile_choices.resize(height)
	sums_of_weights.resize(height)
	sums_of_log_weights.resize(height)
	entropies.resize(height)
	
	for row in range(height):
		wave_output[row].resize(width)
		possible_tile_choices[row].resize(width)
		sums_of_weights[row].resize(width)
		sums_of_log_weights[row].resize(width)
		entropies[row].resize(width)
		for col in range(width):
			wave_output[row][col] ="."
			possible_tile_choices[row][col] = PossibleTiles.new(TILES)
			sums_of_weights[row][col] = 0.0
			sums_of_log_weights[row][col] = 0.0
			entropies[row][col] = 0.0
	
	weights.resize(tiles_count)
	log_weights.resize(tiles_count)
	distribution.resize(tiles_count)
	
	# compute weights using Shannon Entropy
	# Source: https://github.com/mxgmn/WaveFunctionCollapse/blob/master/Model.cs
	# starts at line 55 of source code link
	for t in range(tiles_count):
		weights[t] = 2.0 # equal weight
		log_weights[t] = weights[t] * log(weights[t])
		sum_of_weights += weights[t]
		sum_of_log_weights += log_weights[t]
	
	assert(sum_of_weights > 0)
	starting_entropy = log(sum_of_weights) - (sum_of_log_weights / sum_of_weights)
	
	banned_tiles_stack.resize(width * height)
	stack_size = 0

func clear():
	pass

func pick_unobserved_cell():
	pass
	
func observe_cell():
	pass
	
func propagate_constraints() -> bool:
	return false
	
func ban_tile(cell_position: Vector2i, tile_index: int):
	assert(tile_index >= 0 and tile_index < len(TILES))
	var tile: String = TILES[tile_index]
	possible_tile_choices[cell_position.y][cell_position.x].remove(tile)
	
	banned_tiles_stack[stack_size] = BannedTile.new(cell_position, tile_index)
	stack_size += 1
	
	# add banned tile to final output
	wave_output[cell_position.y][cell_position.x] = tile
	
	# update weights
	sums_of_weights[cell_position.y][cell_position.x] -= weights[tile_index]
	sums_of_log_weights[cell_position.y][cell_position.x] -= log_weights[tile_index]
	
	# recompute shannon entropy
	var sums: float = sums_of_weights[cell_position.y][cell_position.x]
	entropies[cell_position.y][cell_position.x] = log(sums) - sums_of_log_weights[cell_position.y][cell_position.x] / sums 
	
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


func _ready():
	button.pressed.connect(run)
