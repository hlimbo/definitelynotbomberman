extends CharacterBody2D
class_name Player
"""
Player controller
- Walk, dash, and bomb‑throw mechanics
- Clear separation of responsibilities for maintainability
"""

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
@export var max_bounces: int = 4

var _charge: float    = 0.0
var _charging: bool   = false
var _bomb_scene: PackedScene = preload("res://nodes/Bomb.tscn")

# ─────────────────────────────────────────────────────────────────────────────
#   ── Aim reticle ──
# ─────────────────────────────────────────────────────────────────────────────
@onready var _aim_line: Line2D = $"AimLine"
@export var aim_line_length: float = 32.0
var _aim_dir: Vector2 = Vector2.ZERO

# ─────────────────────────────────────────────────────────────────────────────
#   ── Visuals & animation ──
# ─────────────────────────────────────────────────────────────────────────────
@onready var _sprite: Sprite2D      = $"Sprite2D"
@onready var _anim: AnimationPlayer = $"AnimationPlayer"

# ─────────────────────────────────────────────────────────────────────────────
#   ── Input helpers ──
# ─────────────────────────────────────────────────────────────────────────────
func _get_move_input() -> Vector2:
	"""Return normalized WASD / arrow‑key vector."""
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()

# ─────────────────────────────────────────────────────────────────────────────
#   ── Life‑cycle ──
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	# Bomb charge / release handling
	if event.is_action_pressed("throw_bomb"):
		_start_charging()
	elif event.is_action_released("throw_bomb") and _charging:
		_launch_bomb()

	# Dash detection must NOT call missing event methods –
	# use the Input singleton instead of the event.
	if Input.is_action_just_pressed("dash") and _can_dash():
		_begin_dash()

func _physics_process(delta: float) -> void:
	_update_dash(delta)
	_update_walk(delta)
	move_and_slide()
	_update_animation()

func _process(delta: float) -> void:
	_update_charge(delta)
	_update_aim_line()

# ─────────────────────────────────────────────────────────────────────────────
#   ── Dash logic ──
# ─────────────────────────────────────────────────────────────────────────────
func _begin_dash() -> void:
	_is_dashing = true
	_dash_timer = dash_duration
	_cooldown_timer = dash_cooldown
	_dash_dir = _get_move_input()
	if _dash_dir == Vector2.ZERO:
		_dash_dir = _aim_dir   # default to aim direction

func _update_dash(delta: float) -> void:
	if _is_dashing:
		_dash_timer -= delta
		velocity = _dash_dir * dash_speed
		if _dash_timer <= 0.0:
			_is_dashing = false
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

	# Slow while charging a bomb.
	if _charging:
		velocity *= 0.5

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
	var speed: float = lerp(200.0, max_launch_speed, power)

	var bomb: Node2D = _bomb_scene.instantiate()
	bomb.position = global_position + _aim_dir * 20.0
	bomb.launch(_aim_dir, speed, max_bounces)
	get_tree().current_scene.get_node("BombContainer").add_child(bomb)

# ─────────────────────────────────────────────────────────────────────────────
#   ── Aim & reticle ──
# ─────────────────────────────────────────────────────────────────────────────
func _update_aim_line() -> void:
	_aim_dir = (get_global_mouse_position() - global_position).normalized()

	_aim_line.points = [Vector2.ZERO, _aim_dir * aim_line_length]
	_aim_line.width  = 2.0

	var pct: float = clampf(_charge / max_charge_time, 0.0, 1.0)
	if pct < 1.0:
		_aim_line.modulate = Color.WHITE.lerp(Color.RED, pct)
	else:
		var phase: float = sin(Time.get_ticks_msec() * TAU * 8.0 / 1000.0)
		_aim_line.modulate = Color.WHITE.lerp(Color.RED, (phase + 1.0) * 0.5)

	# Flip sprite based on aim x‑direction.
	_sprite.flip_h = _aim_dir.x < 0

# ─────────────────────────────────────────────────────────────────────────────
#   ── Animation ──
# ─────────────────────────────────────────────────────────────────────────────
func _update_animation() -> void:
	if _is_dashing:
		_anim.play("dash")
	elif velocity.length() > 0.1:
		_anim.play("walk")
	else:
		_anim.stop()
