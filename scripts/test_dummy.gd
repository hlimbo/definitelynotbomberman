extends Node

### dependencies
@export var event_bus: EventBus = EventBus

func _ready():
	event_bus.on_start_explosion.connect(on_start_explosion)
	event_bus.on_end_explosion.connect(on_end_explosion)
	

func on_start_explosion(explosion: BaseExplosion):
	print("an explosion started: %s" % explosion.name)
	
func on_end_explosion(explosion: BaseExplosion):
	print("an explosion ended: %s" % explosion.name)
