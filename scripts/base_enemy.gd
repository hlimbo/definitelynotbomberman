class_name BaseEnemy extends Node2D

### dependencies
@export var event_bus: EventBus = EventBus

enum AI_State
{
	IDLE,
	FOLLOW,
	HURT,
	DEATH,
	ATTACK,
}

@export var starting_hp: float = 1000.0
@export var hp: float
@export var follow_speed: float = 100.0
@export var follow_distance: float = 32.0
@export var ai_state: AI_State = AI_State.IDLE
var prev_ai_state: AI_State = ai_state
@export var target: Node2D
@export var damage_text_node: PackedScene
@export var hurt_shader: Shader
@export var death_shader: Shader

@export var curr_move_velocity: Vector2 = Vector2(0.0, 0.0)

@onready var detection_area: Area2D = $DetectionArea
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea
@onready var damage_text_root: Node2D = $DamageTextRoot
@onready var hurt_timer: Timer = $hurt_timer
@onready var death_timer: Timer = $death_timer

@onready var aim_line : Line2D = $"AimLine"
var _aim_dir : Vector2 = Vector2.RIGHT
@export var aim_line_length := 32.0

var curr_death_time: float = 0.0

@export var base_damage: float = 50.0

func set_shader(shader: Shader):
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	self.material = shader_mat
	
func clear_shader():
	self.material = null

func can_attack() -> bool:
	return ai_state != AI_State.ATTACK and (is_instance_valid(target) and position.distance_to(target.position) < follow_distance)

func _ready():
	detection_area.body_entered.connect(on_body_entered)
	event_bus.on_enter_impact_area.connect(on_enter_impact_area)
	event_bus.on_exit_impact_area.connect(on_exit_impact_area)
	hurt_timer.timeout.connect(on_iframes_completed)
	death_timer.timeout.connect(on_death_completed)
	
	hp = starting_hp
	
func on_body_entered(body: Node2D):
	if body.name == "Player" and ai_state == AI_State.IDLE:
		ai_state = AI_State.FOLLOW
		prev_ai_state = ai_state
		target = body
		
func on_iframes_completed():
	ai_state = prev_ai_state
	clear_shader()
	
func on_death_completed():
	queue_free()

func _physics_process(delta_time: float):
	if ai_state == AI_State.FOLLOW:
		if not is_instance_valid(target):
			ai_state = AI_State.IDLE
		else:
			_aim_dir = (target.position - position).normalized()
			follow(delta_time)
	
	aim_line.points = [
		Vector2.ZERO,                          # start at player origin
		_aim_dir * aim_line_length                           # outwards along aim
	]
	
	sprite_2d.flip_h = _aim_dir.x > 0
	
	if can_attack():
		start_attack()
	
func _process(delta: float):
	if ai_state == AI_State.DEATH:
		var shader_mat: ShaderMaterial = (material as ShaderMaterial)
		if is_instance_valid(shader_mat):
			var t: float = 1.0 - curr_death_time / death_timer.wait_time
			shader_mat.set_shader_parameter("alpha", t)
			curr_death_time += delta

#region overridable functions
func on_enter_impact_area(explosion: BaseExplosion, actor: Node):
	# if same actor that received impact, handle the signal, otherwise don't handle it
	if actor != self:
		return
		
	if explosion.is_disabled:
		return
		
	# random damage numbers for fun
	var flat_dmg: float = randf_range(12.0, 512.0) # explosion.flat_dmg
	
	hp -= flat_dmg
	
	if hp > 0:
		ai_state = AI_State.HURT
		set_shader(hurt_shader)
		hurt_timer.start()
	else:
		ai_state = AI_State.DEATH
		set_shader(death_shader)
		hit_area.queue_free()
		detection_area.queue_free()
		death_timer.start()
	
	var damage_text: DamageText = damage_text_node.instantiate()
	damage_text_root.add_child(damage_text)
	damage_text.play_animation(flat_dmg) 
	
func on_exit_impact_area(explosion: BaseExplosion, actor: Node):
	# if same actor that received impact, handle the signal, otherwise don't handle it
	if actor != self:
		return
	
func follow(delta_time: float):
	var diff: Vector2 = target.position - position
	var distance: float = Vector2.ZERO.distance_to(diff)
	var dir: Vector2 = diff.normalized()
	curr_move_velocity = Vector2.ZERO if distance < follow_distance else dir * follow_speed * delta_time
	position = position + curr_move_velocity

func start_attack():
	prev_ai_state = ai_state
	ai_state = AI_State.ATTACK
	
	# send message to target that they are attacked
	event_bus.on_start_attack.emit(self, target)
	
	# can play an attack animation here....
	# once animation finished move back to prev ai state
	ai_state = prev_ai_state
	
#endregion
