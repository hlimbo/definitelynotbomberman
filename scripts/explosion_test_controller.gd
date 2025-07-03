extends Node

@export var scene_root: Node
@export var explosion_node: PackedScene
@onready var spawn_explosion: Button = $SpawnExplosion

const SCREEN_WIDTH = 1200
const SCREEN_HEIGHT = 720


func _ready():
	spawn_explosion.pressed.connect(on_spawn)
	
func on_spawn():
	var explosion: BaseExplosion = explosion_node.instantiate()
	scene_root.add_child(explosion)
	
	# pick a random spot on screen to spawn explosion at
	var pos = Vector2(randf_range(0.0, SCREEN_WIDTH), randf_range(0.0, SCREEN_HEIGHT))
	explosion.start(pos)
