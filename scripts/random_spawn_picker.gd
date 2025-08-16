class_name RandomSpawnPicker extends Node

const INVALID_POSITION = Vector2i(-1, -1)

@export var tile_map_layer: TileMapLayer
# position of the tile map layer node relative to the world position
var root_position: Vector2
var tile_map_layer_scale: Vector2
# x - width in pixels
# y - height in pixels
var tile_dimensions: Vector2i
var tile_map_width: int
var tile_map_height: int

# tile map layer start position offset
var tile_root_position: Vector2i

# represents what positions are valid to spawn packed scenes in
# 2d array of bools
# true - can spawn a packed scene in the given [y][x] tile coordinate position
# false - cannot spawn a packed scene in the given [y][x] tile coordinate position
var available_positions: Array[Array]

func _ready():
	tile_map_layer_scale = tile_map_layer.scale
	tile_dimensions = tile_map_layer.tile_set.tile_size

	# returns enclosing rect space of the tile map layer
	var rect_area: Rect2i = tile_map_layer.get_used_rect()
	root_position = tile_map_layer.position + Vector2(rect_area.position.x * tile_map_layer_scale.x * tile_dimensions.x, rect_area.position.y * tile_map_layer_scale.y * tile_dimensions.y)
	tile_root_position = rect_area.position
	tile_map_width = rect_area.size.x
	tile_map_height = rect_area.size.y

	print("root_position: %v" % root_position)
	print("tile map layer position: %v" % tile_map_layer.position)
	print("rect area position: %v" % rect_area.position)
	print("width: ", tile_map_width)
	print("height: ", tile_map_height)
	print("tile dimensions: %v" % tile_dimensions)

	reset()

func pick_random_spawn_location(excluded_tile_positions_set: Dictionary[Vector2i, bool]) -> Vector2i:
	# collect all randomly available positions
	var valid_positions: Array[Vector2i] = []
	for y in range(tile_map_height):
		for x in range(tile_map_width):
			var possible_position = Vector2i(x, y)
			var is_available: bool = available_positions[y][x]
			if is_available and (possible_position + tile_root_position) not in excluded_tile_positions_set:
				valid_positions.append(possible_position)
	
	var random_index: int = -1 if len(valid_positions) == 0 else randi_range(0, len(valid_positions) - 1)
	if random_index == -1:
		return INVALID_POSITION
	
	var random_position: Vector2i = valid_positions[random_index]
	# mark is unavailable position to spawn in
	available_positions[random_position.y][random_position.x] = false

	# add to tile_root_position to ensure the tiles are placed at the correct offset
	return random_position + tile_root_position

# sets all cell positions as valid positions to randomly place a node on
func reset():
	available_positions = []
	for row in range(tile_map_height):
		available_positions.append([])
		for col in range(tile_map_width):
			available_positions[row].append(true)
	
func convert_tile_coords_to_world_coords(tile_coord: Vector2i) -> Vector2:
	var x_offset: float = tile_coord.x * float(tile_dimensions.x) * tile_map_layer_scale.x
	var y_offset: float = tile_coord.y * float(tile_dimensions.y) * tile_map_layer_scale.y
	var mid_offset: Vector2 = 0.5 * Vector2(float(tile_dimensions.x) * tile_map_layer_scale.x, float(tile_dimensions.y) * tile_map_layer_scale.y)
	# return root_position + Vector2(x_offset, y_offset) + mid_offset
	return Vector2(x_offset, y_offset) + mid_offset

# assumption: all tilemap layers are positioned at (0,0) world coordinates
func convert_world_coords_to_tile_coords(coord: Vector2) -> Vector2i:
	assert(tile_dimensions.x != 0 and tile_dimensions.y != 0)
	var scaled_dimensions = Vector2i(tile_dimensions.x * tile_map_layer.scale.x, tile_dimensions.y * tile_map_layer.scale.y)
	return Vector2i(int(coord.x / scaled_dimensions.x), int(coord.y / scaled_dimensions.y))

func pick_random_world_position(excluded_tile_positions_set: Dictionary[Vector2i, bool] = {}) -> Vector2:
	var spawn_pos: Vector2i = pick_random_spawn_location(excluded_tile_positions_set)
	var spawn_world_pos: Vector2 = convert_tile_coords_to_world_coords(spawn_pos)
	
	print("spawn pos: %.0v" % spawn_pos)
	print("spawn world pos: %v" % spawn_world_pos)
	
	return spawn_world_pos

func compute_dynamically_excluded_positions(excluded_world_positions: Array[Vector2], exclusion_radius: int = 4) -> Dictionary[Vector2i, bool]:
	var excluded_tile_positions: Array[Vector2i] = []
	for excluded_position in excluded_world_positions:
		var excluded_tile_position: Vector2i = convert_world_coords_to_tile_coords(excluded_position)
		excluded_tile_positions.append(excluded_tile_position)
	
	var excluded_tile_positions_set: Dictionary[Vector2i, bool] = {}
	for tile_position in excluded_tile_positions:
		var neighboring_positions: Array[Vector2i] = get_neighboring_positions(tile_position, exclusion_radius)
		excluded_tile_positions_set[tile_position] = true
		for neighbor in neighboring_positions:
			excluded_tile_positions_set[neighbor] = true
	
	print("excluded world positions ", excluded_world_positions)
	print("excluded tile positions ", excluded_tile_positions_set.keys())
	return excluded_tile_positions_set

# radius controls how many units away spawnable objects are not allowed to spawn from
func get_neighboring_positions(tile_position: Vector2i, radius: int = 1) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), # right
		Vector2i(-1, 0), # left
		Vector2i(0, 1), # down
		Vector2i(0, -1), # up
		Vector2i(1, 1), # down-right
		Vector2i(-1, 1), # down-left
		Vector2i(-1, -1), # up-left
		Vector2i(1, -1), # up-right
	]

	for dir in directions:
		for r in range(1, radius + 1):
			var neighbor: Vector2i = tile_position + (r * dir)
			var offset: Vector2i = tile_root_position + Vector2i(tile_map_width, tile_map_height)
			if neighbor.x < tile_root_position.x or neighbor.x >= offset.x or neighbor.y < tile_root_position.y or neighbor.y >= offset.y:
				continue
			
			result.append(neighbor)
	
	return result
