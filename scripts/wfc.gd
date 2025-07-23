# wfc = Wave Function Collapse Algorithm
# https://github.com/mxgmn/WaveFunctionCollapse

extends Node

# goal: have an NxM grid of characters generate a map of characters outputted as console log
# O - Ocean
# M - Mountain
# F - Forest
# S - Sand
const TILES: Array[String] = ["O", "M", "F", "S"]

# Example rule-set
# * Oceans can be next to Sand
# * Sand can be next to Ocean, Mountain or Forest
# * Mountain can be next to Forest or Sand
# * Forest can be next to Mountain or Sand
# The same tile type can be next to each other** e.g. Oceans can be next to Oceans

# used to determine which tiles fit together like a puzzle piece
# this can be thought of as a rule set of which tiles can be connected together
# key - tile string
# value - list of Strings that are compatible with this tile
var compatible_tiles: Dictionary[String, Array] = {
	"O": ["O", "S"],
	"S": ["S", "O", "M", "F"],
	"M": ["M", "F", "S"],
	"F": ["F", "M", "S"]
}

@onready var button: Button = $WFC_Button

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

class PossibleTiles:
	# switch to actual tiles later on
	var tiles: Array[String]
	
	func _init(_tiles: Array[String]):
		tiles = []
		tiles.append_array(_tiles)
	
	func size() -> int:
		return len(tiles)
		
	func get_tile(index: int) -> String:
		assert(index >= 0 and index < len(tiles))
		return tiles[index]
	
	func has_tile(tile: String) -> bool:
		return tile in tiles
	
	func remove(tile: String):
		#assert(tile in tiles)
		var remove_tile_index: int = -1
		for i in range(len(tiles)):
			if tiles[i] == tile:
				remove_tile_index = i
				break
		
		tiles.remove_at(remove_tile_index)

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
	
	weights[0] = 4.0 # ocean
	weights[1] = 2.0 # mountain
	weights[2] = 2.0 # forest
	weights[3] = 16.0 # Sand
	
	# compute weights using Shannon Entropy
	# Source: https://github.com/mxgmn/WaveFunctionCollapse/blob/master/Model.cs
	# starts at line 55 of source code link
	for t in range(tiles_count):
		# weights[t] = 2.0 # equal weight
		log_weights[t] = weights[t] * log(weights[t])
		sum_of_weights += weights[t]
		sum_of_log_weights += log_weights[t]
	
	assert(sum_of_weights > 0)
	starting_entropy = log(sum_of_weights) - (sum_of_log_weights / sum_of_weights)

func clear():
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
			var entropy: float = entropies[row][col]
			var tile_choices: int = possible_tile_choices[row][col].size()
			
			# noise is used here because in the first iteration all cells have the same entropy
			# therefore, noise is added as a tiebreaker
			var noise: float = 1E-6 * fmod(randf(), 1.0)
			
			if tile_choices > 1 and entropy + noise <= min:
				min = entropy + noise
				cell = Vector2i(col, row)
	
	#print("cell picked: ", cell)
	return cell
	
func observe_cell(cell: Vector2i):
	
	# assign tile weights for the given cell inputted
	distribution = []
	var possible_tile_choices_count: int = possible_tile_choices[cell.y][cell.x].size()
	for t in range(possible_tile_choices_count):
		distribution.append(weights[t])

	
	# pick a random tile to place in the given cell
	var sum: float = 0.0
	for t in range(len(distribution)):
		sum += distribution[t]
	
	var threshold: float = fmod(randf(), 1.0) * sum
	var partial_sum: float = 0.0
	var tile_index: int = 0
	for t in range(len(distribution)):
		partial_sum += distribution[t]
		if partial_sum >= threshold:
			tile_index = t
			break
	
	var picked_tile: String = possible_tile_choices[cell.y][cell.x].tiles[tile_index]
	#print("picked tile: ", picked_tile)
	
	# ban all tiles that don't match tile_index for the given cell index -- collapse
	for t in range(tiles_count):
		if picked_tile != TILES[t] and possible_tile_choices[cell.y][cell.x].has_tile(TILES[t]):
			ban_tile(cell, t)

# returns true if any cell has more than 1 tile to pick from from any cell
# returns false otherwise
func propagate_constraints() -> bool:
	while len(banned_tiles_stack) > 0:
		# pick the latest tile banned
		var banned_tile: BannedTile = banned_tiles_stack.pop_back()
		assert(banned_tile != null)
		
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
		
		# if number of tile choices for this position is 0... skip it....
		# this check may be causing the algorithm to stop early even though there are still tiles to be picked
		if possible_tile_choices[banned_tile.cell_position.y][banned_tile.cell_position.x].size() <= 0:
			return true
			# return false
		
		# after the first cell propagation... neighbor of neighbors can have multiple choices so this one needs to be a loop....
		var tiles_union_set: Dictionary[String, bool] = {}
		for picked_tile in possible_tile_choices[banned_tile.cell_position.y][banned_tile.cell_position.x].tiles:
			var compat_tiles: Array = compatible_tiles[picked_tile]
			for compat_tile in compat_tiles:
				tiles_union_set[compat_tile] = true
		
		var length: int = len(tiles_union_set)
		assert(length > 0)
		
		var eliminated_tile_indices: Array[int] = [] 
		
		for t in range(len(TILES)):
			var tile: String = TILES[t]
			if tile not in tiles_union_set:
				eliminated_tile_indices.append(t)
		
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
				
			for t in eliminated_tile_indices:
				if possible_tile_choices[neighbor_position.y][neighbor_position.x].has_tile(TILES[t]):
					ban_tile(neighbor_position, t)
		
	# count number of choices left to make per cell
	var total_choices_left: int = 0
	for row in range(height):
		for col in range(width):
			var choices_left: int = possible_tile_choices[row][col].size()
			# will infinite loop now.....
			# if choices_left > 1:
			total_choices_left += choices_left
	
	return total_choices_left > 0
	
func ban_tile(cell_position: Vector2i, tile_index: int):
	assert(tile_index >= 0 and tile_index < len(TILES))
	var tile: String = TILES[tile_index]
	possible_tile_choices[cell_position.y][cell_position.x].remove(tile)
	
	banned_tiles_stack.append(BannedTile.new(cell_position, tile_index))
	
	# update weights
	sums_of_weights[cell_position.y][cell_position.x] -= weights[tile_index]
	sums_of_log_weights[cell_position.y][cell_position.x] -= log_weights[tile_index]
	
	# recompute shannon entropy
	var sums: float = sums_of_weights[cell_position.y][cell_position.x]
	entropies[cell_position.y][cell_position.x] = log(sums) - sums_of_log_weights[cell_position.y][cell_position.x] / sums 

func print_puzzle():
	print("------------------------PUZZLE-------------------------------")
	for row in range(height):
		var string_row: String = ""
		for col in range(width):
			var choice_count: int = possible_tile_choices[row][col].size()
			if choice_count == 1:
				string_row += possible_tile_choices[row][col].get_tile(0) + " "
			else: # many choices are either still left or no valid tiles can be picked
				string_row += ". "
		
		print(string_row)
	print("---------------------------------------------------------------")

func print_grid_state():
	for row in range(height):
		var row_string: String = ""
		for col in range(width):
			var tiles: Array[String] = possible_tile_choices[row][col].tiles
			row_string +=  "[" + ",".join(tiles) + "]\t"
		print(row_string)

func run() -> bool:
	init()
	clear()
	
	print_grid_state()
	print("-----------------------------")
	
	var is_puzzle_solved: bool = false
	var is_puzzle_in_progress: bool = true
	var iterations: int = 0
	# while you still have a cell to pick a tile from the grid, continue the loop
	# otherwise stop the loop
	while is_puzzle_in_progress:
		if iterations == 9:
			print("last one hardcoded")
		
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
		else:
			# WFC algorithm completed solving the grid map layout
			is_puzzle_solved = true
			is_puzzle_in_progress = false
			
		iterations += 1
		
		#print("------------AFTER----------------")
		#print_grid_state()
		#print("---------------------------------")
			
			
	print_puzzle()
	return is_puzzle_solved

func run_wave_function_collapse():
	var is_successful: bool = run()
	print("is successful? ", is_successful)

func _ready():
	button.pressed.connect(run_wave_function_collapse)
