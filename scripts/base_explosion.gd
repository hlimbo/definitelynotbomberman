class_name BaseExplosion extends Node2D

### dependencies
@export var event_bus: EventBus = EventBus

@export var flat_dmg: float = 12.0
@export var min_dmg: float = 32.0
@export var max_dmg: float = 64.0
@export var explosion_duration: float = 0.3
# used to determine if more collision events should be sent through event bus
# since toggling off collision happens at the end of the frame causing some delays
@export var is_disabled: bool = false

# measured in pixels
@export var min_hit_radius: float = 50.0
@export var max_hit_radius: float = 100.0

@export var base_impact_color: Color = Color.WHITE

@onready var explosion_timer: Timer = $ExplosionTimer
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area_2d: Area2D = $Area2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


@onready var explosion_vfx: Array[GPUParticles2D] = [
	$flare1, $flare2, $flare3, $smoke, $ring, $sparks
]

func _ready():
	assert(len(explosion_vfx) == 6)
	assert(explosion_duration > 0.0)
	explosion_timer.wait_time = explosion_duration
	for vfx in explosion_vfx:
		vfx.lifetime = explosion_duration
	
	explosion_timer.timeout.connect(on_explosion_finished)
	area_2d.area_entered.connect(on_area_entered)
	area_2d.area_exited.connect(on_area_exited)
	
func on_explosion_finished():
	disable()
	queue_free()
	event_bus.on_end_explosion.emit(self)

func start(_position: Vector2 = Vector2.ZERO):
	self.position = _position
	enable()
	explosion_timer.start()
	
	event_bus.on_start_explosion.emit(self)
	
func enable():
	# enables collision shape at end of frame
	collision_shape_2d.set_deferred("disabled", false)
	self.call_deferred("enable_deferred")
	
func disable():
	# disables collision shape at end of frame
	collision_shape_2d.set_deferred("disabled", true)
	self.set_deferred("is_disabled", true)

func enable_deferred():
	var circle_area: CircleShape2D = collision_shape_2d.shape as CircleShape2D
	assert(circle_area != null)
	circle_area.radius = min_hit_radius
	
	is_disabled = false
	play_vfx()

func play_vfx():
	for vfx in explosion_vfx:
		vfx.emitting = true
	
func on_area_entered(area: Area2D):
	if is_disabled:
		return
	
	flat_dmg = randf_range(min_dmg, max_dmg)
	event_bus.on_enter_impact_area.emit(self, area.owner)
	
func on_area_exited(area: Area2D):
	if is_disabled:
		return
		
	event_bus.on_exit_impact_area.emit(self, area.owner)
	
func _physics_process(delta: float):
	if explosion_vfx[0].emitting:
		var impact_circle: CircleShape2D = collision_shape_2d.shape as CircleShape2D
		assert(impact_circle != null)
		var t: float = clampf(1.0 - (explosion_timer.time_left / explosion_duration), 0.0, 1.0)
		var smooth: float = smoothstep(0.0, 1.0, t)
		impact_circle.radius = lerpf(min_hit_radius, max_hit_radius, smooth)
