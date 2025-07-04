class_name BaseEnemy extends Node2D

### dependencies
@export var event_bus: EventBus = EventBus

enum AI_State
{
	IDLE,
	FOLLOW,
	HURT,
	DEATH,
}

@export var follow_speed: float = 100.0
@export var ai_state: AI_State = AI_State.IDLE
var prev_ai_state: AI_State = ai_state
@export var target: Node2D
@export var damage_text_node: PackedScene
@export var hurt_shader: Shader

@export var curr_move_velocity: Vector2 = Vector2(0.0, 0.0)

@onready var detection_area: Area2D = $DetectionArea
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea
@onready var damage_text_root: Node2D = $DamageTextRoot
@onready var hurt_timer: Timer = $hurt_timer



@onready var aim_line : Line2D = $"AimLine"
var _aim_dir : Vector2 = Vector2.RIGHT
@export var aim_line_length := 32.0

func set_shader(shader: Shader):
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	self.material = shader_mat
	
func clear_shader():
	self.material = null

func _ready():
	detection_area.body_entered.connect(on_body_entered)
	event_bus.on_enter_impact_area.connect(on_enter_impact_area)
	event_bus.on_exit_impact_area.connect(on_exit_impact_area)
	hurt_timer.timeout.connect(on_iframes_completed)
	
func on_body_entered(body: Node2D):
	print("on body entered: %s" % body.name)
	if body.name == "Player":
		ai_state = AI_State.FOLLOW
		prev_ai_state = ai_state
		target = body
		
func on_iframes_completed():
	ai_state = prev_ai_state
	clear_shader()

func _physics_process(delta_time: float):
	if ai_state == AI_State.FOLLOW:
		_aim_dir = (target.position - position).normalized()
		follow(delta_time)
	
	aim_line.points = [
		Vector2.ZERO,                          # start at player origin
		_aim_dir * aim_line_length                           # outwards along aim
	]
	
	sprite_2d.flip_h = _aim_dir.x > 0

#region overridable functions
func on_enter_impact_area(explosion: BaseExplosion, actor: Node):
	# if same actor that received impact, handle the signal, otherwise don't handle it
	if actor != self:
		return
	
	print("explosion enter name: %s" % explosion.name)
	
	ai_state = AI_State.HURT
	set_shader(hurt_shader)
	hurt_timer.start()
	
	# random damage numbers for fun
	var flat_dmg: float = randf_range(12.0, 512.0) # explosion.flat_dmg
	var damage_text: DamageText = damage_text_node.instantiate()
	damage_text_root.add_child(damage_text)
	damage_text.play_animation(flat_dmg) 
	
func on_exit_impact_area(explosion: BaseExplosion, actor: Node):
	# if same actor that received impact, handle the signal, otherwise don't handle it
	if actor != self:
		return
	
	print("explosion exit name: %s" % explosion.name)

func follow(delta_time: float):
	var dir: Vector2 = (target.position - position).normalized()
	curr_move_velocity = dir * follow_speed * delta_time
	position = position + curr_move_velocity
#endregion
