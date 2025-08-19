# this script is needed as the Project Settings solution does not
# show the custom mouse cursor on web builds...
class_name WebMouseCursor extends Node2D

@onready var cursor_sprite: Sprite2D = $Sprite2D

func _ready():
	if OS.get_name() == "Web":
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		cursor_sprite.visible = true
	else:
		cursor_sprite.visible = false
		set_process(false)
		set_physics_process(false)
		
func _process(_delta: float):
	self.global_position = get_viewport().get_mouse_position()
