extends CharacterBody2D
class_name Player
"""
Player controller
- Walk, dash, and bomb‑throw mechanics
- Clear separation of responsibilities for maintainability
"""

const EXPLOSION_TYPE_COUNT = 5

# ─────────────────────────────────────────────────────────────────────────────
#   ── Dependencies ──
# ─────────────────────────────────────────────────────────────────────────────
@export var event_bus: EventBus = EventBus
@export var camera_controller: CameraController
@export var bomb_container: Node2D

# ─────────────────────────────────────────────────────────────────────────────
#   ── Movement ──
# ─────────────────────────────────────────────────────────────────────────────
@export var walk_speed: float  = 200.0

# ── Dash tunables
@export var dash_speed: float     = 900.0
@export var dash_duration: float  = 0.20   # seconds
@export var dash_cooldown: float  = 0.60   # seconds

var _is_dashing: bool      = false
var _dash_timer: float     = 0.0
var _cooldown_timer: float = 0.0
var _dash_dir: Vector2     = Vector2.ZERO

# ─────────────────────────────────────────────────────────────────────────────
#   ── Bomb tunables ──
# ─────────────────────────────────────────────────────────────────────────────
@export var max_charge_time: float = 1.2     # seconds
@export var max_launch_speed: float = 800.0  # px/s
@export var min_launch_speed: float = 200.0  # px/s
@export var max_bounces: int = 4


var _charge: float    = 0.0
var _charging: bool   = false
var _bomb_scene: PackedScene = preload("res://nodes/Bomb.tscn")
var _explosion_index: int = 0 # used to pick which explosion to use when swapping between different bombs

# ─────────────────────────────────────────────────────────────────────────────
#   ── Aim reticle ──
# ─────────────────────────────────────────────────────────────────────────────
@onready var _aim_line: Line2D = $"AimLine"
@export var aim_line_length: float = 64.0
var _aim_dir: Vector2 = Vector2.ZERO

# ─────────────────────────────────────────────────────────────────────────────
#   ── Visuals & animation ──
# ─────────────────────────────────────────────────────────────────────────────
@onready var _sprite: Sprite2D      = $"Sprite2D"
@onready var _shadow: Sprite2D = $Shadow
@onready var _anim: AnimationPlayer = $"AnimationPlayer"

@onready var shader_mat: ShaderMaterial
@export var blinking_shader: Shader
@export var death_shader: Shader

@onready var move_particles: GPUParticles2D = $Sprite2D/MoveParticles
@onready var particle_process_mat: ParticleProcessMaterial = ($Sprite2D/MoveParticles.process_material as ParticleProcessMaterial)

@onready var damage_text_root: Node2D = $Sprite2D/DamageTextRoot
@export var damage_text_node: PackedScene = preload("res://nodes/ui/DamageText.tscn")

@export var knockback_force: float = 250.0
@export var knockback_force_vector: Vector2 = Vector2.ZERO

@export var swirl_ratio: float = 1.0
@export var curr_death_timer: float = 0.0

# ─────────────────────────────────────────────────────────────────────────────
#   ── Stats ──
# ─────────────────────────────────────────────────────────────────────────────
@export var starting_hp: float = 1000.0
@export var current_hp: float
@export var is_hurt: bool = false
@export var is_dead: bool = false
@export var is_alive: bool = true
@export var _is_spawning: bool = false

# ─────────────────────────────────────────────────────────────────────────────
#   ── Timers ──
# ─────────────────────────────────────────────────────────────────────────────
@onready var hurt_timer: Timer = $HurtTimer
@onready var death_timer: Timer = $DeathTimer

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# ─────────────────────────────────────────────────────────────────────────────
#   ── Audio ──
# ─────────────────────────────────────────────────────────────────────────────
@onready var dash_audio_player: AudioStreamPlayer2D = $dash_audio_player
@onready var hurt_audio_player: AudioStreamPlayer2D = $hurt_audio_player
@onready var death_audio_player: AudioStreamPlayer2D = $death_audio_player
@onready var throw_audio_player: AudioStreamPlayer2D = $throw_audio_player

# tradeoff: can only play 1 sfx at a time for 1 audio stream player
# to support playing different hurt sfx simultaneously, have different AudioStreamPlayer2D
@export var ranged_enemy_hurt_sfx: AudioStream
@export var dashing_enemy_hurt_sfx: AudioStream
@export var normal_enemy_hurt_sfx: AudioStream

@export var player_id: int
@export var hp_bar: HpUiView

# ─────────────────────────────────────────────────────────────────────────────
#   ── Input helpers ──
# ─────────────────────────────────────────────────────────────────────────────
func _get_move_input() -> Vector2:
	"""Return normalized WASD / arrow‑key vector."""
	return float(visible) * float(is_alive) * float(!is_dead) * Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()

# ─────────────────────────────────────────────────────────────────────────────
#   ── Getters ──
# ─────────────────────────────────────────────────────────────────────────────
func get_collision_shape() -> CapsuleShape2D:
	var shape: CapsuleShape2D = $CollisionShape2D.shape as CapsuleShape2D
	assert(shape != null)
	return shape
	
# ─────────────────────────────────────────────────────────────────────────────
#   ── Life‑cycle ──
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	assert(bomb_container != null)
	
	# 1 second is added to the death audio player stream to allow the death visual effect to fully play out
	death_timer.wait_time = death_audio_player.stream.get_length() + 1.0
	
	event_bus.on_start_attack.connect(_on_attacked)
	event_bus.on_projectile_hit.connect(_on_projectile_hit)
	event_bus.on_player_bomb_switched.connect(_on_bomb_switched)
	
	if hp_bar == null or !is_instance_valid(hp_bar):
		push_warning("Player.gd script is missing the hp_bar ui node reference!")
	else:
		hp_bar.set_actor_node(self)
	
	player_id = self.get_canvas_item().get_id()
	print("emitting on initialize hp as player")
	event_bus.on_initialize_hp.emit(player_id, starting_hp, starting_hp)
	
	hurt_timer.timeout.connect(_on_hurt_finished)
	death_timer.timeout.connect(_on_death_finished)
	shader_mat = (material as ShaderMaterial)
	current_hp = starting_hp
	
	camera_controller.add_target(self)
	visible = false
	event_bus.on_game_start.connect(_play_spawn_animation)

func _input(event: InputEvent) -> void:
	if _is_spawning or !is_visible:
		return
	
	# Bomb charge / release handling
	if event.is_action_pressed("throw_bomb"):
		_start_charging()
	elif event.is_action_released("throw_bomb") and _charging:
		# reset audio player to play from beginning if already playing
		# useful when spamming the throw bomb action
		if throw_audio_player.playing:
			throw_audio_player.seek(0.0)
		else:
			throw_audio_player.play()
		_launch_bomb()

	# Dash detection must NOT call missing event methods –
	# use the Input singleton instead of the event.
	if Input.is_action_just_pressed("dash") and _can_dash():
		_begin_dash()

func _physics_process(delta: float) -> void:
	if _is_spawning:
		return
	
	_update_dash(delta)
	_update_walk(delta)
	_update_knockback(delta)
	move_and_slide()

func _process(delta: float) -> void:
	_update_charge(delta)
	_update_aim_line(delta)
	_update_animation()
	_update_camera()

# ─────────────────────────────────────────────────────────────────────────────
#   ── Dash logic ──
# ─────────────────────────────────────────────────────────────────────────────
func _begin_dash() -> void:
	if is_dead or _is_dashing or !visible or _is_spawning:
		return
	
	dash_audio_player.play()
	_is_dashing = true
	_dash_timer = dash_duration
	_cooldown_timer = dash_cooldown
	_dash_dir = _get_move_input()
	if _dash_dir == Vector2.ZERO:
		_dash_dir = _aim_dir   # default to aim direction

func _update_dash(delta: float) -> void:
	if is_dead or _is_spawning or !visible:
		_is_dashing = false
		_cooldown_timer = 0.0
	
	if _is_dashing:
		camera_controller.motion_kind = CameraController.MotionKind.INTERPOLATION
		_dash_timer -= delta
		velocity = _dash_dir * dash_speed
		if _dash_timer <= 0.0:
			_is_dashing = false
			camera_controller.motion_kind = CameraController.MotionKind.INSTANT
	elif _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)

func _can_dash() -> bool:
	return not _is_dashing and _cooldown_timer == 0.0

# ─────────────────────────────────────────────────────────────────────────────
#   ── Walking logic ──
# ─────────────────────────────────────────────────────────────────────────────
func _update_walk(_delta: float) -> void:
	if _is_dashing:
		return   # dash overrides normal movement

	var move_dir: Vector2 = _get_move_input()
	velocity = move_dir * walk_speed

	# walking particle effects direction
	particle_process_mat.direction = Vector3(-move_dir.x, -move_dir.y, 0.0);
	particle_process_mat.emission_shape_offset = Vector3(-move_dir.x * 24.0, 40.0, 0.0)
	# hide particles behind player if moving down; otherwise show in front of player
	if move_dir.y > 0:
		move_particles.z_index = 2
	else:
		move_particles.z_index = 10
	
	if move_dir.x == 0.0:
		move_particles.z_index = 2
		particle_process_mat.emission_shape_offset.y = 20.0


	# Slow while charging a bomb.
	if _charging:
		velocity *= 0.5
		move_particles.amount = 2
	else:
		move_particles.amount = 12

# ─────────────────────────────────────────────────────────────────────────────
#   ── Knockback logic ──
# ─────────────────────────────────────────────────────────────────────────────
var _current_hop_time: float = 0.0 # seconds
var _hop_time: float = 1.0 # time from lift-off to next impact
func _update_knockback(_delta: float) -> void:
	if !is_alive or (!is_hurt and !is_dead):
		return
	
	var knockback_decay: float = 0.1
	# Exponential decay with max speed limit quadratic
	var squared: float = (1.0 - knockback_decay * _delta) * (1.0 - knockback_decay * _delta)
	var decaying_force: float = knockback_force_vector.length() * squared
	knockback_force_vector = knockback_force_vector.normalized() * min(decaying_force, knockback_force)
	
	
	if is_dead:
		var t: float = curr_death_timer / death_timer.wait_time
		swirl_ratio = clampf(1.0 - lerpf(0.0, 1.0, t), 0.0 ,1.0)
		shader_mat.set_shader_parameter(&"ratio", swirl_ratio)
		curr_death_timer += _delta
	else:
		# -- vertical motion of player sprite -- #
		var _amplitude: float = 64.0 # apex-height of the player's perceived vertical when knocked back
		const Y_OFFSET: int = -20 # y-pivot offset of the player's sprite2D asset
		_current_hop_time += _delta
		var phase  := clampf(_current_hop_time / _hop_time, 0.0, 1.0)
		# currently feels floaty when getting knocked back... for polish purposes can use easing functions later...
		var height := sin(phase * PI) * _amplitude

		_sprite.position  = Vector2(0, -height - Y_OFFSET)
		# Shadow Shrink & lighten as player rises
		var t : float = clamp(height / _amplitude, 0.0, 1.0)
		var s : float = lerp(0.5, 0.2, t)
		_shadow.scale = Vector2.ONE * s * 0.1
		_shadow.modulate.a = lerp(0.6, 0.15, t)
	
	if knockback_force_vector.is_equal_approx(Vector2.ZERO):
		camera_controller.motion_kind = CameraController.MotionKind.INSTANT
	else:
		camera_controller.motion_kind = CameraController.MotionKind.INTERPOLATION
	
	velocity += knockback_force_vector

# ─────────────────────────────────────────────────────────────────────────────
#   ── Bomb logic ──
# ─────────────────────────────────────────────────────────────────────────────
func _start_charging() -> void:
	_charging = true
	_charge = 0.0

func _update_charge(delta: float) -> void:
	if _charging:
		_charge = clampf(_charge + delta, 0.0, max_charge_time)
	else:
		_charge = 0.0

func _launch_bomb() -> void:
	_charging = false

	var power: float = _charge / max_charge_time  # 0–1
	var speed: float = lerp(min_launch_speed, max_launch_speed, power)

	var bomb: Bomb = _bomb_scene.instantiate()
	bomb.position = global_position + _aim_dir * 20.0
	bomb.launch(_aim_dir, speed, max_bounces, _explosion_index)
	bomb_container.add_child(bomb)
	
	var bomb_type: Constants.BombType = _explosion_index as Constants.BombType
	event_bus.on_bomb_thrown.emit(bomb_type)

# ─────────────────────────────────────────────────────────────────────────────
#   ── Aim & reticle ──
# ─────────────────────────────────────────────────────────────────────────────
func _update_aim_line(_delta: float) -> void:
	var center_to_mouse_diff: Vector2 = get_global_mouse_position() - global_position
	_aim_dir = center_to_mouse_diff.normalized()
	#aim_line_length = Vector2.ZERO.distance_to(center_to_mouse_diff)

	_aim_line.points = [Vector2.ZERO, _aim_dir * aim_line_length]
	# _aim_line.width  = 2.0

	var pct: float = clampf(_charge / max_charge_time, 0.0, 1.0)
	if pct < 1.0:
		_aim_line.modulate = Color.WHITE.lerp(Color.RED, pct)
	else:
		var phase: float = sin(Time.get_ticks_msec() * TAU * 8.0 / 1000.0)
		_aim_line.modulate = Color.WHITE.lerp(Color.RED, (phase + 1.0) * 0.5)

	# increase aim line length when charging
	if _charging:
		var charge_distance: float = lerp(min_launch_speed, max_launch_speed, pct)
		_aim_line.points = [Vector2.ZERO, _aim_dir * charge_distance]

	# Flip sprite based on aim x‑direction.
	_sprite.flip_h = _aim_dir.x < 0

# ─────────────────────────────────────────────────────────────────────────────
#   ── Animation ──
# ─────────────────────────────────────────────────────────────────────────────
func _update_animation() -> void:
	if _is_spawning:
		return
	
	if is_hurt:
		_anim.play(&"hurt")
		move_particles.emitting = false
	elif is_dead:
		if !_anim.is_playing() or _anim.current_animation != "death":
			_anim.play(&"death")
			move_particles.emitting = false
	elif !is_alive:
		_anim.play(&"invisible")
		move_particles.emitting = false
	elif _is_dashing:
		move_particles.emitting = true
	elif velocity.length() > 0.1:
		_anim.play("walk")
		move_particles.emitting = true
	else:
		_anim.stop()
		move_particles.emitting = false

func _play_spawn_animation():
	if _is_spawning:
		return
	
	_is_spawning = true
	visible = true
	_anim.animation_finished.connect(_on_animation_finished, ConnectFlags.CONNECT_ONE_SHOT)
	_anim.play(&"spawn")

func _on_animation_finished(_anim_name: StringName):
	_is_spawning = false
	_anim.play(&"RESET")

# ─────────────────────────────────────────────────────────────────────────────
#   ── Camera ──
# ─────────────────────────────────────────────────────────────────────────────
func _update_camera() -> void:
	var dist: float = (self.position - camera_controller.position).length()
	var tolerance: float = 16.0
	if dist > tolerance:
		camera_controller.move_to_position_by_index(0)

# ─────────────────────────────────────────────────────────────────────────────
#   ── Signal Callbacks ──
# ─────────────────────────────────────────────────────────────────────────────
func _on_attacked(enemy: BaseEnemy, target: Node2D):
	# if not being actively targetted by the enemy, skip
	# this check is useful if more than 1 player instance is in game
	if target != self:
		return
	
	if !is_alive or is_hurt or is_dead:
		return

	# display damage above player
	var damage_text: DamageText = damage_text_node.instantiate()
	damage_text_root.add_child(damage_text)
	damage_text.play_animation(enemy.base_damage)
	
	current_hp -= enemy.base_damage
	event_bus.on_hp_updated.emit(player_id, enemy.base_damage)
	
	# compute knockback force
	var player_from_enemy_dir: Vector2 = (global_position - enemy.global_position).normalized()
	knockback_force_vector = player_from_enemy_dir * knockback_force
	
	# determine which hurt sfx to play based on enemy type
	if enemy is DashingEnemy:
		hurt_audio_player.set_stream(dashing_enemy_hurt_sfx)
	else:
		hurt_audio_player.set_stream(normal_enemy_hurt_sfx)
	
	hurt_audio_player.play()
	
	if current_hp > 0:
		is_hurt = true
		shader_mat.shader = blinking_shader
		hurt_timer.start()
	else:
		is_dead = true
		knockback_force_vector = Vector2.ZERO
		shader_mat.shader = death_shader
		death_audio_player.play()
		death_timer.start()

func _on_projectile_hit(projectile: Projectile, target: Node2D):
	# if not the same target, skip
	if self != target or target is not Player:
		return
	
	if is_hurt:
		return
	
	# if already dead, don't re-trigger the death animation
	if !self.is_alive or self.is_dead or self.is_queued_for_deletion():
		return
	
	# display damage above player
	var damage_text: DamageText = damage_text_node.instantiate()
	damage_text_root.add_child(damage_text)
	damage_text.play_animation(projectile.base_damage)
	
	current_hp -= projectile.base_damage
	event_bus.on_hp_updated.emit(player_id, projectile.base_damage)
	
	hurt_audio_player.set_stream(ranged_enemy_hurt_sfx)
	hurt_audio_player.play()
	
	if current_hp > 0:
		is_hurt = true
		shader_mat.shader = blinking_shader
		hurt_timer.start()
	else:
		is_dead = true
		knockback_force_vector = Vector2.ZERO
		shader_mat.shader = death_shader
		death_audio_player.play()
		death_timer.start()

func _on_bomb_switched(explosion_index: int):
	assert(explosion_index >= 0 and explosion_index < EXPLOSION_TYPE_COUNT)
	self._explosion_index = explosion_index

func _on_hurt_finished():
	is_hurt = false
	_current_hop_time = 0.0
	_anim.play(&"RESET")
	shader_mat.shader = null

func _on_death_finished():
	event_bus.on_game_end.emit("GameOver")
	
	# destroy this gameobject
	is_dead = false
	is_alive = false
	_current_hop_time = 0.0
	velocity = Vector2(0.0, 0.0)
	queue_free()
