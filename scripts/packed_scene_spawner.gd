class_name PackedSceneSpawner extends Node

@export var event_bus: EventBus = EventBus

@export var weight_table: WeightTable
@export var random_spawn_picker: RandomSpawnPicker

@export var spawn_count: int = 12

@onready var spawn_delay_timer: Timer = $spawn_delay_timer

var enemy_index: int = 0
var nodes: Array[Node] = []

func spawn_random_scene() -> Node:
	var scene: PackedScene = weight_table.pick_random_spawnable()
	var node: Node = scene.instantiate()
	return node
	
func _ready():
	weight_table.construct()
	for i in range(spawn_count):
		var node: Node = spawn_random_scene()
		nodes.append(node)
	
	spawn_delay_timer.timeout.connect(on_spawn_enemy)

func start_spawning():
	spawn_delay_timer.start()

func on_spawn_enemy():
	if enemy_index >= len(nodes):
		spawn_delay_timer.stop()
	else:
		var base_enemy: BaseEnemy = nodes[enemy_index] as BaseEnemy
		self.add_child(base_enemy)
		var position: Vector2 = random_spawn_picker.pick_random_world_position()
		base_enemy.position = position
		
		enemy_index += 1
