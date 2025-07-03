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


func _ready():
	detection_area.body_entered.connect(on_body_entered)
	
func on_body_entered(body: Node2D):
	print("on body entered: %s" % body.name)
	if body.name == "Player":
		ai_state = AI_State.FOLLOW
		target = body
		
func _physics_process(delta_time: float):
	if ai_state == AI_State.FOLLOW:
		follow(delta_time)
		
func follow(delta_time: float):
	var dir: Vector2 = (target.position - position).normalized()
	curr_move_velocity = dir * follow_speed * delta_time
	position = position + curr_move_velocity
	
