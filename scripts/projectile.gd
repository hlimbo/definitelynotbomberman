class_name Projectile extends Node2D

### dependencies
@export var event_bus: EventBus = EventBus

@onready var hit_area: Area2D = $HitArea

@export var speed: float = 300.0 # measured in pixels per second
var dir: Vector2 = Vector2.ZERO

@export var lifetime_duration: float = 3.0 # how many seconds this lasts before being destroyed
var curr_duration: float = 0.0

@export var base_damage: float = 10.0

func launch(_position: Vector2, _dir: Vector2):
	self.position = _position
	self.dir = _dir

func on_impact(other: Node2D):
	if other is Player:
		event_bus.on_projectile_hit.emit(self, other)
		queue_free()

func _ready():
	hit_area.body_entered.connect(on_impact)

func _physics_process(delta: float):
	curr_duration += delta
	
	if curr_duration >= lifetime_duration:
		queue_free()
	else:
		var velocity: Vector2 = dir * speed * delta
		position += velocity
