class_name BaseExplosion extends Node2D

### dependencies
@export var event_bus: EventBus = EventBus

@export var flat_dmg: float = 0.0
@export var explosion_duration: float = 0.0
# used to determine if more collision events should be sent through event bus
# since toggling off collision happens at the end of the frame causing some delays
@export var is_disabled: bool = false

@onready var explosion_timer: Timer = $ExplosionTimer
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area_2d: Area2D = $Area2D


@onready var explosion_vfx: Array[GPUParticles2D] = [
	$flare1, $flare2, $flare3, $smoke, $ring, $sparks
]

func _ready():
	explosion_timer.wait_time = explosion_duration
	explosion_timer.timeout.connect(on_explosion_finished)
	area_2d.area_entered.connect(on_area_entered)
	area_2d.area_exited.connect(on_area_exited)
	
func on_explosion_finished():
	print("on explosion finished")
	disable()
	queue_free()
	event_bus.on_end_explosion.emit(self)

func start(position: Vector2 = Vector2.ZERO):
	self.position = position
	enable()
	explosion_timer.start()
	
	event_bus.on_start_explosion.emit(self)
	
func enable():
	# enables collision shape at end of frame
	collision_shape_2d.set_deferred("disabled", false)
	is_disabled = false
	play_vfx()
	
func disable():
	# disables collision shape at end of frame
	collision_shape_2d.set_deferred("disabled", true)
	is_disabled = true

func play_vfx():
	for vfx in explosion_vfx:
		vfx.emitting = true
		
func on_area_entered(area: Area2D):
	if is_disabled:
		return
	
	event_bus.on_enter_impact_area.emit(self, area.owner)
	
func on_area_exited(area: Area2D):
	if is_disabled:
		return
	
	print("explosion exited")
	event_bus.on_exit_impact_area.emit(self, area.owner)
