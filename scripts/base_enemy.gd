class_name BaseEnemy extends Node2D

enum AI_State
{
	IDLE,
	FOLLOW,
	HURT,
	DEATH,
}

@export var follow_speed: float = 100.0
@export var ai_state: AI_State = AI_State.IDLE
@export var target: Node2D

@export var curr_move_velocity: Vector2 = Vector2(0.0, 0.0)

@onready var detection_area: Area2D = $DetectionArea
@onready var sprite_2d: Sprite2D = $Sprite2D


@onready var aim_line : Line2D = $"AimLine"
var _aim_dir : Vector2 = Vector2.RIGHT
@export var aim_line_length := 32.0

func _ready():
	detection_area.body_entered.connect(on_body_entered)
	
func on_body_entered(body: Node2D):
	print("on body entered: %s" % body.name)
	if body.name == "Player":
		ai_state = AI_State.FOLLOW
		target = body
		
func _physics_process(delta_time: float):
	if ai_state == AI_State.FOLLOW:
		_aim_dir = (target.position - position).normalized()
		follow(delta_time)
	
	aim_line.points = [
		Vector2.ZERO,                          # start at player origin
		_aim_dir * aim_line_length                           # outwards along aim
	]
	
	sprite_2d.flip_h = _aim_dir.x > 0
	
func follow(delta_time: float):
	var dir: Vector2 = (target.position - position).normalized()
	curr_move_velocity = dir * follow_speed * delta_time
	position = position + curr_move_velocity
	
