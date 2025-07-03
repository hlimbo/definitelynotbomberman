extends CharacterBody2D

const SPEED := 200.0
@export var max_charge_time := 1.2            # seconds
@export var max_launch_speed := 800.0         # px/s
@export var max_bounces := 4         # num bounces before exploding

var _charge := 0.0
var _charging := false
@export var _bomb_scene := preload("res://nodes/Bomb.tscn")

@onready var aim_line : Line2D = $"AimLine"
var _aim_dir : Vector2 = Vector2.ZERO
@export var aim_line_length := 32.0

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
	else:
		_charge = 0.0
	# === draw line/reticle ===
	_aim_dir = (get_global_mouse_position() - global_position).normalized()
	aim_line.points = [
		Vector2.ZERO,                          # start at player origin
		_aim_dir * aim_line_length                           # outwards along aim
	]
	var charge_pct : float = clamp(_charge / max_charge_time, 0.0, 1.0)         # 0 – 1
	aim_line.scale      = Vector2.ONE
	aim_line.width     = 2.0
	if charge_pct < 1.0:
		# grow red as pct rises
		aim_line.modulate = Color.WHITE.lerp(Color.RED, charge_pct)
	else:
		# full charge: flash between red and white
		var phase  := sin(Time.get_ticks_msec() * 8.0 * TAU / 1000.0)
		var blend  := (phase + 1.0) * 0.5            # 0 – 1 pulse
		aim_line.modulate = Color.WHITE.lerp(Color.RED, blend)
		
func _throw_bomb():
	var power := _charge / max_charge_time          # 0 → 1
	var speed : float = lerp(200.0, max_launch_speed, power)
	
	var bomb := _bomb_scene.instantiate()
	bomb.position = global_position + _aim_dir * 20      # spawn in front of player
	#bomb.linear_velocity = dir * speed
	bomb.launch(_aim_dir, speed, max_bounces)
	get_tree().current_scene.get_node("BombContainer").add_child(bomb)
	
func _physics_process(delta):
	var move_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()
	velocity = move_dir * SPEED
	move_and_slide()
