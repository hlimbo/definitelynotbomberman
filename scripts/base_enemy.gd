class_name BaseEnemy extends CharacterBody2D

### dependencies
@export var event_bus: EventBus = EventBus

#region Status Effects
const POISON: String = "POISON"
const GRAVITY: String = "GRAVITY"
const SLOW: String = "SLOW"
const ROOT: String = "ROOT"
#endregion

enum AI_State
{
	INACTIVE,
	IDLE,
	FOLLOW,
	HURT,
	ATTACK,
	PREP_ATTACK,
	DEATH,
}

@export var starting_hp: float = 1000.0
@export var hp: float
@export var follow_speed: float = 100.0 # pixels per second
@export var follow_distance: float = 32.0
@export var ai_state: AI_State = AI_State.INACTIVE
@export var target: Node2D
@export var damage_text_node: PackedScene
@export var hurt_shader: Shader
@export var death_shader: Shader

@export var curr_move_velocity: Vector2 = Vector2(0.0, 0.0)

@onready var detection_area: Area2D = $DetectionArea
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea
@onready var damage_text_root: Node2D = $DamageTextRoot
@onready var ai_state_label: Label = $DebugTextRoot/AIStateLabel
@onready var hurt_timer: Timer = $hurt_timer
@onready var death_timer: Timer = $death_timer
@onready var debuff_timer: Timer = $debuff_timer
@onready var debuff_frequency_timer: Timer = $debuff_frequency_timer
@onready var gravity_timer: Timer = $gravity_timer
@onready var root_timer: Timer = $root_timer
@onready var slow_timer: Timer = $slow_timer
@onready var hurt_audio_player: AudioStreamPlayer2D = $hurt_audio_player
@onready var death_audio_player: AudioStreamPlayer2D = $death_audio_player

@onready var aim_line : Line2D = $"AimLine"
var _aim_dir : Vector2 = Vector2.RIGHT
@export var aim_line_length := 32.0

var curr_death_time: float = 0.0

@export var base_damage: float = 50.0

@export var applied_status_effects: Array[String] = []

var gravity_center_position: Vector2 = Vector2.ZERO
var gravity_max_force_scalar: float = 0
var gravity_decay_percentage: float = 0
var gravity_force_per_physics_step: float = 0
var gravity_radius: float = 0
var accumulated_pull_force: Vector2 = Vector2.ZERO

var slow_factor: float = 0.0

func set_shader(shader: Shader):
	var shader_mat: ShaderMaterial = sprite_2d.material as ShaderMaterial
	assert(shader_mat != null)
	shader_mat.shader = shader
	
func clear_shader():
	var shader_mat: ShaderMaterial = sprite_2d.material as ShaderMaterial
	assert(shader_mat != null)
	shader_mat.shader = null

func remove_all_signal_connections(signal_ref: Signal):
	var connections: Array = signal_ref.get_connections()
	for connection in connections:
		signal_ref.disconnect(connection["callable"])

func can_attack() -> bool:
	return AI_State.FOLLOW == ai_state and (is_instance_valid(target) and position.distance_to(target.position) < follow_distance)

func _ready():
	detection_area.body_entered.connect(on_body_entered)
	event_bus.on_enter_impact_area.connect(on_enter_impact_area)
	event_bus.on_exit_impact_area.connect(on_exit_impact_area)
	hurt_timer.timeout.connect(on_iframes_completed)
	death_timer.timeout.connect(on_death_completed)
	debuff_timer.timeout.connect(on_debuff_completed)
	gravity_timer.timeout.connect(on_gravity_completed)
	root_timer.timeout.connect(on_root_completed)
	slow_timer.timeout.connect(on_slow_completed)
	
	# create a separate shader material instance from other enemies that get spawned in
	var shader_mat: ShaderMaterial = ShaderMaterial.new()
	sprite_2d.material = shader_mat
	
	hp = starting_hp
	# ai_state = AI_State.IDLE

# gets called when about to leave the SceneTree
func _exit_tree():
	ai_state = AI_State.INACTIVE
	sprite_2d.visible = false
	visible = false
	
func on_body_entered(body: Node2D):
	if body.name == "Player" and ai_state == AI_State.IDLE:
		ai_state = AI_State.FOLLOW
		target = body
		
func on_iframes_completed():
	ai_state = AI_State.FOLLOW
	clear_shader()
	
func on_death_completed():
	queue_free()

func find_and_remove_status_effect(status_effect: String):
	var effect_index: int = -1
	for i in range(len(applied_status_effects)):
		if applied_status_effects[i] == status_effect:
			effect_index = i
			break
			
	if effect_index != -1:
		applied_status_effects.remove_at(effect_index)

func on_debuff_completed():
	find_and_remove_status_effect(POISON)

func on_gravity_completed():
	# remove the accumulated pull force from this enemy
	if not self.velocity.is_zero_approx():
		self.velocity -= accumulated_pull_force
	else:
		self.velocity = Vector2.ZERO
	
	accumulated_pull_force = Vector2.ZERO
	find_and_remove_status_effect(GRAVITY)

func on_root_completed():
	find_and_remove_status_effect(ROOT)
	
func on_slow_completed():
	print("slow done")
	find_and_remove_status_effect(SLOW)
	slow_factor = 0.0

func on_debuff_applied(dmg: float):
	print("apply debuff with dmg: %f" % dmg)
	var damage_text: DamageText = damage_text_node.instantiate()
	damage_text_root.add_child(damage_text)
	damage_text.play_animation(dmg)
	
	hp -= dmg
	
	if hp <= 0.0 and ![AI_State.INACTIVE, AI_State.DEATH].has(ai_state):
		ai_state = AI_State.DEATH
		self.velocity = Vector2(0.0, 0.0)
		set_shader(death_shader)
		death_timer.start()
		if !death_audio_player.playing:
			death_audio_player.play()
		self.disable()
	
	# final tick
	var is_debuff_complete: bool = debuff_timer.time_left <= 0.0
	if is_debuff_complete:
		debuff_frequency_timer.stop()
		remove_all_signal_connections(debuff_frequency_timer.timeout)

func _physics_process(delta_time: float):
	self.handle_states()
	
	# handle status effects
	if applied_status_effects.has(GRAVITY):
		var diff: Vector2 = gravity_center_position - position
		var dist_to_center: float = diff.length()
		var pull_dir: Vector2 = diff.normalized()
		
		
		# the closer it is to the center, the less influence it has
		# the further away it is from the center, the more influence it has
		var dist_factor: float = dist_to_center / gravity_radius
		# note: goto desmos graphing calculator to visualize 1.0 + e^x
		var acceleration_factor: float = (1.0 + exp(dist_to_center)) * gravity_force_per_physics_step
		var pull_vector: Vector2 = pull_dir * acceleration_factor
		var temp_pull_force: Vector2 = accumulated_pull_force + pull_vector
		
		# cap accumulated_pull_force to max pull force scalar
		var pull_length: float = temp_pull_force.length()
		if pull_length > gravity_max_force_scalar:
			accumulated_pull_force = pull_dir * gravity_max_force_scalar * delta_time
		else:
			accumulated_pull_force += pull_vector * delta_time
		
		# sets accumulated force to zero if exactly at center of explosion
		accumulated_pull_force *= dist_factor
		
		self.velocity = accumulated_pull_force
		
		# reduce gravity force per physics step by a percentage
		var kept_force_percentage: float = 1.0 - gravity_decay_percentage
		gravity_force_per_physics_step *= kept_force_percentage
	
	if applied_status_effects.has(ROOT):
		self.velocity = Vector2.ZERO
	
	if applied_status_effects.has(SLOW):
		self.velocity = self.velocity - (self.velocity * slow_factor)
	
	aim_line.points = [
		Vector2.ZERO,                         
		_aim_dir * aim_line_length
	]
	
	sprite_2d.flip_h = _aim_dir.x > 0
	
	if can_attack():
		start_attack()
	
	# apply all velocities/accelerations
	self.move_and_slide()
	
func _process(delta: float):
	update_ai_state_label()
	if ai_state == AI_State.DEATH:
		var t: float = clampf(1.0 - curr_death_time / death_timer.wait_time, 0.0, 1.0)
		sprite_2d.set_instance_shader_parameter("alpha", t)
		curr_death_time += delta
			
func update_ai_state_label():
	match ai_state:
		AI_State.IDLE:
			ai_state_label.text = "IDLE"
		AI_State.FOLLOW:
			ai_state_label.text = "FOLLOW"
		AI_State.HURT:
			ai_state_label.text = "HURT"
		AI_State.DEATH:
			ai_state_label.text = "DEATH"
		AI_State.ATTACK:
			ai_state_label.text = "ATTACK"
		AI_State.PREP_ATTACK:
			ai_state_label.text = "PREP_ATTACK"
		AI_State.INACTIVE:
			ai_state_label.text = "INACTIVE"

func handle_enter_explosion_area(explosion: BaseExplosion):
	if explosion is PoisonExplosion:
		# if already poisoned don't apply it again for simplicity... would need to implement a stacking system and reset timer when new poison stack is given
		if not applied_status_effects.has(POISON):
			applied_status_effects.append(POISON)
			var poison_explosion = explosion as PoisonExplosion
			debuff_timer.wait_time = poison_explosion.debuff_duration
			debuff_frequency_timer.wait_time = poison_explosion.debuff_frequency
			
			debuff_frequency_timer.timeout.connect(on_debuff_applied.bind(poison_explosion.dot_dmg))
			debuff_timer.start()
			debuff_frequency_timer.start()
	elif explosion is GravityExplosion:
		if not applied_status_effects.has(GRAVITY):
			applied_status_effects.append(GRAVITY)
			var gravity_explosion = explosion as GravityExplosion
			gravity_center_position = gravity_explosion.position
			gravity_max_force_scalar = gravity_explosion.max_pull_force
			gravity_force_per_physics_step = gravity_explosion.pull_force_per_physics_step
			gravity_decay_percentage = gravity_explosion.pull_decay
			gravity_radius = gravity_explosion.gravity_radius
			gravity_timer.start(gravity_explosion.explosion_duration)
	elif explosion is GooExplosion:
		if not applied_status_effects.has(SLOW):
			applied_status_effects.append(SLOW)
			var goo_explosion = explosion as GooExplosion
			print("%s slowed!" % self.name)
			slow_timer.wait_time = goo_explosion.slow_duration
			slow_factor = goo_explosion.slow_factor
			slow_timer.start()
	elif explosion is RootExplosion:
		if not applied_status_effects.has(ROOT):
			applied_status_effects.append(ROOT)
			var root_explosion = explosion as RootExplosion
			root_timer.wait_time = root_explosion.root_duration
			print("%s rooted!"  % self.name)
			root_timer.start()
		
	
	# Default Explosion Behavior
	# random damage numbers for fun
	var flat_dmg: float = randf_range(12.0, 512.0) # explosion.flat_dmg
	
	var damage_text: DamageText = damage_text_node.instantiate()
	damage_text_root.add_child(damage_text)
	damage_text.play_animation(flat_dmg) 
	
	hp -= flat_dmg
	
	# default hurt and death logic
	if hp > 0 and ![AI_State.HURT, AI_State.INACTIVE, AI_State.DEATH].has(ai_state):
		ai_state = AI_State.HURT
		self.velocity = Vector2(0.0, 0.0)
		set_shader(hurt_shader)
		hurt_timer.start()
		self.interrupt()
		hurt_audio_player.play()
	elif ![AI_State.INACTIVE, AI_State.DEATH, AI_State.HURT].has(ai_state):
		ai_state = AI_State.DEATH
		self.velocity = Vector2(0.0, 0.0)
		set_shader(death_shader)
		death_audio_player.play()
		self.disable()
		death_timer.start()
	
func handle_exit_explosion_area(explosion: BaseExplosion):
	pass

#region overridable functions
func disable():
	target = null # stop having enemy follow player
	debuff_timer.stop()
	debuff_frequency_timer.stop()
	slow_timer.stop()
	root_timer.stop()
	gravity_timer.stop()
	
	# turn off collision layer scanning
	hit_area.collision_layer = 0
	detection_area.collision_layer = 0
	
	# turn off collison mask scanning
	hit_area.collision_mask = 0
	detection_area.collision_mask = 0
	

# used to stop timers that aren't in the BaseEnemy class such as DashingEnemy timers
func interrupt():
	pass

func handle_states():
	if ai_state == AI_State.FOLLOW:
		if not is_instance_valid(target):
			ai_state = AI_State.IDLE
		else:
			_aim_dir = (target.position - position).normalized()
			follow()
	elif ai_state == AI_State.IDLE:
		self.velocity = Vector2.ZERO
		self.accumulated_pull_force = Vector2.ZERO
	elif ai_state == AI_State.INACTIVE:
		self.velocity = Vector2.ZERO
		self.accumulated_pull_force = Vector2.ZERO

func on_enter_impact_area(explosion: BaseExplosion, actor: Node):
	# if same actor that received impact, handle the signal, otherwise don't handle it
	if actor != self:
		return
		
	if explosion.is_disabled:
		return
	
	# enemies have i-frames or is dead
	if [AI_State.HURT, AI_State.DEATH, AI_State.INACTIVE].has(ai_state):
		return
	
	# handle specific explosion type
	handle_enter_explosion_area(explosion)
	
func on_exit_impact_area(explosion: BaseExplosion, actor: Node):
	# if same actor that received impact, handle the signal, otherwise don't handle it
	if actor != self:
		return
		
	handle_exit_explosion_area(explosion)
	
func follow():
	var diff: Vector2 = target.position - position
	var distance: float = Vector2.ZERO.distance_to(diff)
	var dir: Vector2 = diff.normalized()
	curr_move_velocity = Vector2.ZERO if distance < follow_distance else dir * follow_speed
	self.velocity = curr_move_velocity

func start_attack():
	ai_state = AI_State.ATTACK
	
	# send message to target that they are attacked
	event_bus.on_start_attack.emit(self, target)
	
	# can play an attack animation here....
	# once animation finished move back to prev ai state
	ai_state = AI_State.FOLLOW
	
#endregion
