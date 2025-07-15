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
	
	# filters out locations in the maze that are already visited or out of bounds
	directions = directions.filter(func (direction: Array):
		var new_row: int = row + direction[0]
		var new_col: int = col + direction[1]
		
		var is_out_of_bounds: bool = new_row < 0 or new_row >= height or new_col < 0 or new_col >= width
		var new_location: String = "%d-%d" % [new_row, new_col]
		var is_visited: bool = visited_set.has(new_location)
		return !is_out_of_bounds and !is_visited
	)
	
	# randomize the directions list order to simulate picking random paths to create
	directions.shuffle()
	for direction in directions:
		var new_row: int = row + direction[0]
		var new_col: int = col + direction[1]
		
		# add passage from current location to neighbor
		maze[row + direction[0] / 2][col + direction[1] / 2] = TileType.Connection
		dfs_generate(new_row, new_col, width, height, maze, visited_set)

func _ready():
	_wall_padding_width = width - 1
	_wall_padding_height = height - 1
	_width = width + _wall_padding_width
	_height = height + _wall_padding_height
	
	init_maze()
	print_maze()
	
	print("\n")
	dfs_generate(0, 0, _width, _height, maze, visited_set)
	print_maze()
