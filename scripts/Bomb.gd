class_name Bomb extends CharacterBody2D

@export var explosion_node: PackedScene

var _amplitude : float       # current hop height
var _t         : float = 0.0 # time inside current hop
var _bounces   : int   = 0
var _blast_radius    :float = 96.0
var _first_amplitude :float = 64.0           # initial hop height (px)
var _restitution     : float= 0.70           # vertical amplitude multiplier per bounce
var _ground_restitution :float= 0.7        # 0 – 1; 1 = no slow-down

const Y_OFFSET        : int= 16

var _speed : float = 450.0
var _direction : Vector2 = Vector2.ZERO
var _damage          :float= 50
var _max_bounces : int = 4              # after this → explode
var _hop_time        :float= 0.40           # time from lift-off to next impact

@onready var _bomb   : Sprite2D = $"BombSprite"
@onready var _shadow : Sprite2D = $"ShadowSprite"

func launch(dir: Vector2, ground_speed: float, max_bounces: int) -> void:
	_direction  = dir.normalized()
	_speed      = ground_speed
	_max_bounces = max_bounces
	_amplitude = _first_amplitude

func _physics_process(delta: float) -> void:
	# ── 1. ground motion ─────────────────────────────────────────
	var vel : Vector2 = _direction * _speed
	var collision : KinematicCollision2D = move_and_collide(vel * delta)
	if collision: #with walls
		# reflect and damp
		var n := collision.get_normal()              # wall normal
		vel = vel.bounce(n) * _ground_restitution
		_direction = vel.normalized();
		# optional: count wall hits toward the bounce limit
		if _bounces >= _max_bounces:
			_explode()

	# ── 2. vertical motion (unchanged) ───────────────────────────
	_t += delta
	var phase  := _t / _hop_time
	if phase >= 1.0:
		_next_bounce()
		phase = _t / _hop_time
	var height := sin(phase * PI) * _amplitude

	_bomb.position  = Vector2(0, -height - Y_OFFSET)
	_shadow.position = Vector2.ZERO

	_update_shadow(height)
	
	# increase flash frequency the more bounces the bomb makes
	var t: float = clampf(float(_bounces) / float(_max_bounces), 0.0, 1.0)
	var min_blink_frequency: float = 3.0
	var max_blink_frequency: float = 8.0
	var curr_blink_frequency: float = lerpf(min_blink_frequency, max_blink_frequency, t)
	_bomb.set_instance_shader_parameter(&"blink_frequency_instance", floorf(curr_blink_frequency))

func _next_bounce() -> void:
	_t = 0.0
	_bounces += 1
	_amplitude *= _restitution # vertical loss
	_speed *= _ground_restitution # horizontal loss
	if _bounces >= _max_bounces:
		_explode()

func _update_shadow(h: float) -> void:
	# Shrink & lighten as bomb rises
	var t : float = clamp(h / _first_amplitude, 0.0, 1.0)
	var s : float = lerp(0.5, 0.2, t)
	_shadow.scale = Vector2.ONE * s * 0.1
	_shadow.modulate.a = lerp(0.6, 0.15, t)

func _explode() -> void:
	var explosion: BaseExplosion = explosion_node.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.start(_shadow.global_position)
	queue_free()
