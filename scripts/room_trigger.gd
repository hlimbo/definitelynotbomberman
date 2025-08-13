class_name RoomTrigger extends Area2D

@export var hazards_layer: TileMapLayer

signal on_enter_room()

func _ready():
	self.body_entered.connect(on_body_entered, ConnectFlags.CONNECT_ONE_SHOT)

func on_body_entered(body: Node2D):
	if body is Player:
		on_enter_room.emit()
		
func enable_hazards():
	hazards_layer.visible = true
	hazards_layer.collision_enabled = true
	
func disable_hazards():
	hazards_layer.visible = false
	hazards_layer.collision_enabled = false
