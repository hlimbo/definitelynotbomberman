class_name BaseExplosion extends Node2D

### dependencies
@export var event_bus: EventBus = EventBus

@export var flat_dmg: float = 0.0
@export var explosion_duration: float = 0.0

@onready var explosion_timer: Timer = $ExplosionTimer
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

@onready var explosion_vfx: Array[GPUParticles2D] = [
	$flare1, $flare2, $flare3, $smoke, $ring, $sparks
]

func _ready():
	explosion_timer.wait_time = explosion_duration
	explosion_timer.timeout.connect(on_explosion_finished)
	
func on_explosion_finished():
	print("on explosion finished")
	disable()
	event_bus.on_end_explosion.emit(self)

func start(position: Vector2 = Vector2.ZERO):
	print("starting explosion")
	self.position = position
	enable()
	explosion_timer.start()
	
	event_bus.on_start_explosion.emit(self)
	
func enable():
	# enables collision shape at end of frame
	collision_shape_2d.set_deferred("disabled", false)
	play_vfx()
	
func disable():
	# disables collision shape at end of frame
	collision_shape_2d.set_deferred("disabled", true)

func play_vfx():
	for vfx in explosion_vfx:
		vfx.emitting = true
