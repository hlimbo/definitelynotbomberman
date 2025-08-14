class_name PackedSceneSpawner extends Node

@export var event_bus: EventBus = EventBus

@export var weight_table: WeightTable
@export var random_spawn_picker: RandomSpawnPicker
@export var marker: Marker2D
# node to attach spawned packed scenes to -- defaults to current scene's root node
@export var parent_spawner_node: Node2D

@export var is_debug_mode_on: bool = false
var debug_markers: Array[Marker2D] = []

@export var spawn_count: int = 12

@onready var spawn_delay_timer: Timer = $spawn_delay_timer

signal on_spawning_finished

var spawn_index: int = 0
var nodes: Array[Node] = []
var is_spawning: bool = false

func spawn_random_scene() -> Node:
	var scene: PackedScene = weight_table.pick_random_spawnable()
	var node: Node = scene.instantiate()
	return node

# this will depend on the player object as it needs to know its position in real time
# to avoid spawning enemies in that location
func _ready():
	assert(parent_spawner_node != null)
	assert(random_spawn_picker != null)
	weight_table.construct()
	spawn_delay_timer.timeout.connect(on_spawn_node)
	
	if parent_spawner_node == null:
		push_warning("PackedSceneManager is missing a reference to parent_spawner_node. Ensure a Node2D reference is assigned to parent_spawner_node to remove the warning. Defaulting to current scene as root node.")
		parent_spawner_node = self.get_tree().current_scene

func start_spawning(count: int = spawn_count):
	if is_spawning:
		return
	
	is_spawning = true
	spawn_count = count
	for i in range(spawn_count):
		var node: Node = spawn_random_scene()
		nodes.append(node)
	
	random_spawn_picker.reset()
	spawn_delay_timer.start()

func stop_spawning():
	is_spawning = false
	spawn_delay_timer.stop()

func on_spawn_node():
	if spawn_index >= len(nodes):
		stop_spawning()
		on_spawning_finished.emit()
	else:
		var node: Node = nodes[spawn_index]
		parent_spawner_node.add_child(node)
		var position: Vector2 = random_spawn_picker.pick_random_world_position()
		node.position = position
		spawn_index += 1
		
		if is_debug_mode_on:
			var clone: Marker2D = marker.duplicate()
			# TODO: add node that will hold all child nodes spawned in for better scene node management
			clone.visible = true
			self.get_tree().current_scene.add_child(clone)
			debug_markers.append(clone)
			clone.position = position
		
