class_name BombPickup extends Node2D

@export var event_bus: EventBus = EventBus
@onready var pickup_area: Area2D = $PickupArea

@export var bomb_type: Constants.BombType = Constants.BombType.DEFAULT

func _ready():
	pickup_area.body_entered.connect(on_body_entered)
	
func on_body_entered(body: Node2D):
	if body is Player:
		# return a random range of bombs
		var count: int = randi_range(4, 16)
		event_bus.on_bomb_picked_up.emit(bomb_type, count)
