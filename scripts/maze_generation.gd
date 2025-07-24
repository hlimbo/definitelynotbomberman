extends Node

enum MazeType
{
	DFS,
	Kruskal,
	DFS_Kruskal_Hybrid,
	WaveFunctionCollapse,
}

enum TileType
{
	Path,
	Wall,
	Connection,
}

@export var maze_type: MazeType = MazeType.DFS


@export var width: int = 3
@export var height: int = 3
var _wall_padding_width: int = 2
var _wall_padding_height: int = 2
var _width: int
var _height: int

# a 2d matrix of TileType
var maze: Array[Array]
# key = String that represents row,col of maze whose format is 0-1 for example
# value = bool that represents if the given row col in the maze is visited or not
var visited_set: Dictionary[String, bool] = {}

@onready var floating_islands: TileMapLayer = $floating_islands
@onready var maze_tile_map_layer: TileMapLayer = $maze

@export var recreate_maze_btn: Button


# limitation: can uniquely identify a tile if you have exactly 1 TileSource in the TileSet
# otherwise, would need to include a nested dictionary or something to identify which tile set source the tile coordinate id is from
# key - TileType enum used to categorize a group of tiles e.g. floor, wall, water, etc
# value - array of possible tiles to use (atlas coordinate ids Vector2i)
var tile_lookup_table: Dictionary[TileType, Array] = {}
var tile_set_source: TileSetSource

class UnionFind:
	var parent: Array[int] = []
	var rank: Array[int] = []
	
	func _init(n: int):
		# data structure - array
		# index represents the 1D position of a cell in the maze
		# value represents who the parent or root of this position is
		self.parent.append_array(range(n))
		
		# rank helps balance tree structure
		self.rank.resize(n)
	
	# find the root of x's group using recursion
	func find(x: int) -> int:
		if self.parent[x] != x:
			self.parent[x] = self.find(self.parent[x])
			
		return self.parent[x]

	# this returns true if the 2 1D positions in the maze are disjoint, false
	# if they already share the same parent
	# x represents the 1D index of a cell in a 2D grid
	# y represents the 1D index of a cell in a 2D grid
	func union(x: int, y: int) -> bool:
		# merge the groups of x and y
		var root_x: int = self.find(x)
		var root_y: int = self.find(y)
		
		# if already in same group, return False --> this means they share same root already
		if root_x == root_y:
			return false
			
		# merge groups (attach smaller tree to larger tree)
		if self.rank[root_x] < self.rank[root_y]:
			var temp: int = root_x
			root_x = root_y
			root_y = temp
			
		# make root_x be the parent of root_y
		self.parent[root_y] = root_x
		
		# update rank if trees were same height
		if self.rank[root_x] == self.rank[root_y]:
			self.rank[root_x] += 1
		
		return true

func init_maze():
	maze = []
	var err = maze.resize(_height)
	if err != OK:
		printerr("failed to set the height of the maze")
	for row in range(len(maze)):
		var maze_row: Array[TileType] = []
		err = maze_row.resize(_width)
		if err != OK:
			printerr("failed to set width of the maze")
		
		maze_row.fill(TileType.Wall)
		maze[row] = maze_row

func print_maze():
	for row in range(len(maze)):
		var string_row: String = ""
		for col in range(len(maze[row])):
			string_row += "%d\t" % maze[row][col]
		print("%s" % string_row)
	print("\n\n")

# source: https://www.cs.cmu.edu/~112-s23/notes/student-tp-guides/Mazes.pdf
func dfs_generate(row: int, col: int, width: int, height: int, maze: Array[Array], visited_set: Dictionary[String, bool]):
	assert(row >= 0 and row < height)
	assert(col >= 0 and col < width)
	
	var location: String = "%d-%d" % [row, col]
	visited_set[location] = true
	# mark current location as a path
	maze[row][col] = TileType.Path
	
	# 2 is used because every other space in the maze is a wall
	var directions: Array = [
		[0, -2], # north
		[0, 2], # south
		[2, 0], # east
		[-2, 0], # west
	]
		
	# randomize the directions list order to simulate picking random paths to create
	directions.shuffle()
	for direction in directions:
		var new_row: int = row + direction[0]
		var new_col: int = col + direction[1]
		
		var new_location: String = "%d-%d" % [new_row, new_col]
		
		# filters out locations in the maze that are already visited or out of bounds
		var is_out_of_bounds: bool = new_row < 0 or new_row >= height or new_col < 0 or new_col >= width
		if is_out_of_bounds or visited_set.has(new_location):
			continue
		
		# add passage from current location to neighbor
		maze[row + direction[0] / 2][col + direction[1] / 2] = TileType.Connection
		dfs_generate(new_row, new_col, width, height, maze, visited_set)

func kruskal_generate(width: int, height: int, maze: Array[Array]):
	# enumerate all possible connections (undirected edges) in the maze
	# ensure all possible connections are unique
	# 2 is used because the assumption is that every other row is a wall
	var directions: Array = [
		[0, -2], # north
		[0, 2], # south
		[2, 0], # east
		[-2, 0], # west
	]
	
	# key - from location represented as String in form of "0-1" for example
	# value - neighbors of to location represented as String in form of "1-1" for example
	var from_to_connections: Dictionary[String, Array] = {}
	var to_from_connections: Dictionary[String, Array] = {}
	for row in range(0, height, 2):
		for col in range(0, width, 2):
			var location: String = "%d-%d" % [row, col]
			for direction in directions:
				# if an edge is already connected, skip as 0-1 and 1-0 are considered to be same
				if to_from_connections.has(location):
					continue
				
				var new_row: int = row + direction[0]
				var new_col: int = col + direction[1]
				var neighbor_location: String = "%d-%d" % [new_row, new_col]
				var is_in_bounds: bool = new_row >= 0 and new_row < height and new_col >=0 and new_col < width
				if is_in_bounds:
					if not from_to_connections.has(location):
						from_to_connections[location] = []
					if not to_from_connections.has(neighbor_location):
						to_from_connections[neighbor_location] = []
						
						
					
					from_to_connections[location].append(neighbor_location)
					to_from_connections[neighbor_location].append(location)

	
	# shuffle connections to randomize which possible connections to visit and connect
	var connections: Array[Array] = []
	for from_location in from_to_connections:
		var to_locations: Array = from_to_connections[from_location]
		for to_location in to_locations:
			connections.append([from_location, to_location])
			#print(connections.back())
	
	connections.shuffle()
	
	var union_find = UnionFind.new(width * height)
	
	for connection in connections:
		# extract locations from string format %d-%d
		var tokens: PackedStringArray = connection[0].split("-")
		var from_row: int = int(tokens[0])
		var from_col: int = int(tokens[1])
		
		tokens = connection[1].split("-")
		var to_row: int = int(tokens[0])
		var to_col: int = int(tokens[1])
		
		# convert 2D coordinates to 1D
		var cell1: int = from_row * width + from_col
		var cell2: int = to_row * width + to_col
		
		# if cells are not in same set, connect them
		if union_find.union(cell1, cell2):
			# mark connection in maze
			maze[from_row][from_col] = TileType.Path
			maze[to_row][to_col] = TileType.Path
			
			# mark connection path
			var y_dir: int = (to_row - from_row) / 2
			var x_dir: int = (to_col - from_col) / 2
			maze[from_row + y_dir][from_col + x_dir] = TileType.Connection

func build_maze():
	assert(maze_tile_map_layer.tile_set.get_source_count() > 0)
	
	var source_id: int = maze_tile_map_layer.tile_set.get_source_id(0)
	tile_set_source = maze_tile_map_layer.tile_set.get_source(source_id)
	
	# IMPROVEMENT: can create an editor extension tool to categorize which tiles belong to which type grouping
	# manually pick which tiles are floor or walls for now
	
	var floor_coordinate_id = Vector2i(4,1)
	tile_lookup_table[TileType.Path] = [floor_coordinate_id]
	var grass_tile_coordinate_id = Vector2i(19, 0)
	tile_lookup_table[TileType.Connection] = [grass_tile_coordinate_id]

	var wall_id = Vector2i(2,5)
	tile_lookup_table[TileType.Wall] = [wall_id]
	
	for r in range(_height):
		for c in range(_width):
			var map_coords = Vector2i(c, r)
			
			var tile_type: TileType = maze[r][c]
			var tile_atlas_coord_id: Vector2i = tile_lookup_table[tile_type][0]
			maze_tile_map_layer.set_cell(map_coords, source_id, tile_atlas_coord_id)

func _ready():
	_wall_padding_width = width - 1
	_wall_padding_height = height - 1
	_width = width + _wall_padding_width
	_height = height + _wall_padding_height
	
	create_maze()
	
	if recreate_maze_btn != null:
		recreate_maze_btn.pressed.connect(on_recreate_maze_pressed)
		

func clear_maze():
	# delete all cells
	maze_tile_map_layer.clear()
	
	init_maze()
	visited_set.clear()

func create_maze():
	# delete all cells
	maze_tile_map_layer.clear()
	
	init_maze()
	
	match maze_type:
		MazeType.DFS:
			dfs_generate(0, 0, _width, _height, maze, visited_set)
		MazeType.Kruskal:
			kruskal_generate(_width, _height, maze)

	build_maze()

func on_recreate_maze_pressed():
	clear_maze()
	create_maze()
