class_name CameraController extends Node2D

enum MotionKind {
	INSTANT, # set position directly
	INTERPOLATION, # use interpolation to move camera precisely from one position to the next over a set time duration
	PHYSICS, # use velocity and forces to move camera each frame
}

@onready var camera_2d: Camera2D = $Camera2D

# last target is the most recent target to follow
# first target is the least recent target to follow
@export var targets: Array[Node2D] = []
@export var target_positions: Array[Vector2] = []

@export var motion_kind: MotionKind

# interpolation
var curr_interpolation_time: float = 0.0
@export var movement_delay_duration: float = 0.5 # seconds

# physics
@export var move_speed: float = 200.0

var curr_position: Vector2
var next_position: Vector2
var is_new_position_set: bool = false

func get_average_position() -> Vector2:
	assert(len(target_positions) > 0)
	var vector_sum: Vector2 = Vector2.ZERO
	for target_position in target_positions:
		vector_sum += target_position
	
	return vector_sum / len(targets)
	
func get_median_position() -> Vector2:
	assert(len(target_positions) > 0)
	var half_index: int = int(len(target_positions) / 2)
	if len(target_positions) % 2 == 0:
		return 0.5 * (target_positions[half_index] + target_positions[half_index + 1])
	
	return target_positions[half_index]
	
func move_to_average_position():
	if is_new_position_set:
		return
	
	curr_interpolation_time = 0.0
	curr_position = position
	next_position = get_average_position()
	is_new_position_set = true
	
func move_to_median_position():
	if is_new_position_set:
		return
	
	curr_interpolation_time = 0.0
	curr_position = position
	next_position = get_median_position()
	is_new_position_set = true

func move_to_position_by_index(index: int):
	if is_new_position_set:
		return
	
	assert(index >= 0 and index < len(target_positions))
	curr_interpolation_time = 0.0
	curr_position = position
	next_position = target_positions[index]
	is_new_position_set = true
	
func move_to_position(_position: Vector2):
	if is_new_position_set:
		return
	
	assert(_position in target_positions)
	curr_interpolation_time = 0.0
	curr_position = position
	next_position = _position
	is_new_position_set = true

func add_target(target: Node2D) -> bool:
	if target in targets:
		return false
	
	targets.append(target)
	target_positions.append(target.position)
	return true
	
func remove_target(target: Node2D) -> bool:
	var remove_index: int = -1
	for i in range(len(targets)):
		if targets[i] == target:
			remove_index = i
			break
	
	if remove_index == -1:
		return false
	
	targets.remove_at(remove_index)
	target_positions.remove_at(remove_index)
	return true

# used to determine if node targets are queued for deletion or already been deleted and cleaning up the list
# to ensure only non-null node targets are being tracked
func check_if_targets_valid():
	assert(len(target_positions) == len(targets))
	var removed_target_indices: Array[int] = []
	
	for i in range(len(target_positions)):
		if targets[i] == null or !is_instance_valid(targets[i]) or targets[i].is_queued_for_deletion():
			removed_target_indices.append(i)
			
	for remove_index in removed_target_indices:
		targets.remove_at(remove_index)
		target_positions.remove_at(remove_index)

func update_positions():
	assert(len(target_positions) == len(targets))
	for i in range(len(target_positions)):
		# if the previous check for validity is missed, skip setting its position for this frame
		if !is_instance_valid(targets[i]) or targets[i].is_queued_for_deletion():
			continue
		target_positions[i] = targets[i].position

func _process(delta: float):
	check_if_targets_valid()
	update_positions()
	
	if is_new_position_set:
		match motion_kind:
			MotionKind.INSTANT:
				position = next_position
				is_new_position_set = false
			MotionKind.INTERPOLATION:
				interpolate_to_next_position(delta)
			MotionKind.PHYSICS:
				apply_velocity_towards_next_position(delta)
				

func interpolate_to_next_position(delta: float):
	var ratio: float = curr_interpolation_time / movement_delay_duration
	var smoothing_ratio: float = smoothstep(0.0, 1.0, ratio)
	position = curr_position.lerp(next_position, smoothing_ratio)
	curr_interpolation_time += delta
	
	if ratio >= 1.0:
		is_new_position_set = false
	
	
func apply_velocity_towards_next_position(delta: float):
	var diff: Vector2 = (position - next_position)
	var dir: Vector2 = -1.0 * diff.normalized()
	position = position + dir * move_speed * delta
	
	var tolerance: float = 16.0 # 8.0
	var dist: float = diff.length()
	if dist < tolerance:
		is_new_position_set = false
