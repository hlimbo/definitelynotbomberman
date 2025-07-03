class_name BaseExplosion extends Node2D

### dependencies
@export var event_bus: EventBus = EventBus

@export var flat_dmg: float = 0.0
@export var dot_dmg: float = 0.0
@export var slow_factor: float = 0.0

@export var explosion_duration: float = 0.0
@export var dot_duration: float = 0.0
@export var slow_duration: float = 0.0
@export var root_duration: float = 0.0

@onready var explosion_timer: Timer = $ExplosionTimer
@onready var explosion_vfx: Sprite2D = $ExplosionVfx

func _ready():
	explosion_timer.wait_time = explosion_duration
	explosion_timer.timeout.connect(on_explosion_finished)
	
func on_explosion_finished():
	print("on explosion finished")
	explosion_vfx.visible = false
	event_bus.on_end_explosion.emit(self)

func start():
	print("starting explosion")
	explosion_timer.start()
