# wfc = Wave Function Collapse Algorithm
# https://github.com/mxgmn/WaveFunctionCollapse

extends Node

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
