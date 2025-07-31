class_name PackedSceneSpawner extends Node

@export var event_bus: EventBus = EventBus

@export var weight_table: WeightTable
@export var random_spawn_picker: RandomSpawnPicker

func spawn_random_scene() -> Node:
	var scene: PackedScene = weight_table.pick_random_spawnable()
	var node: Node = scene.instantiate()
	self.add_child(node)
	return node
	
func _ready():
	weight_table.construct()
	var nodes: Array[Node] = []
	for i in range(4):
		var node: Node = spawn_random_scene()
		nodes.append(node)
		
	for i in range(len(nodes)):
		var base_enemy: BaseEnemy = nodes[i] as BaseEnemy
		var position: Vector2 = random_spawn_picker.pick_random_world_position()
		base_enemy.position = position
