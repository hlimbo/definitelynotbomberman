extends CharacterBody2D

const SPEED := 200.0
@export var max_charge_time := 1.2            # seconds
@export var max_launch_speed := 800.0         # px/s
@export var max_bounces := 4         # num bounces before exploding

var _charge := 0.0
var _charging := false
var _bomb_scene := preload("res://Bomb.tscn")

func _input(event):
	if event.is_action_pressed("throw_bomb"):
		_charging = true
		_charge = 0.0
	elif event.is_action_released("throw_bomb") and _charging:
		_charging = false
		_throw_bomb()

func _process(delta):
	if _charging:
		_charge = clamp(_charge + delta, 0, max_charge_time)
		# optional UI feedback e.g. scale reticle
		
func _throw_bomb():
	var power := _charge / max_charge_time          # 0 → 1
	var speed : float = lerp(200.0, max_launch_speed, power)
	var dir := (get_global_mouse_position() - global_position).normalized()
	
	var bomb := _bomb_scene.instantiate()
	bomb.position = global_position + dir * 20      # spawn in front of player
	#bomb.linear_velocity = dir * speed
	bomb.launch(dir, speed, max_bounces)
	get_tree().current_scene.get_node("BombContainer").add_child(bomb)
	
func _physics_process(delta):
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()
	velocity = dir * SPEED
	move_and_slide()
