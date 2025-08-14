class_name WaveManager extends Node

enum WaveState {
	START,
	IDLE,
	SPAWNING,
	FINISHED,
}

### Dependencies
@export var event_bus: EventBus = EventBus
@export var mob_spawners: Array[PackedSceneSpawner] = []
@export var parent_spawner_node: Node2D

@export var min_wave_count: int = 2
@export var max_wave_count: int = 3
@export var min_enemies_to_spawn_per_wave: int = 2
@export var max_enemies_to_spawn_per_wave: int = 6

@export var wave_index: int = 0
@export var wave_count: int = 1
@export var enemies_per_wave: int = 2
@export var enemy_wave_spawn_delay: float = 0.25 # seconds
@export var mob_spawner_index: int = 0

@export var wave_state: WaveState = WaveState.START

signal on_all_waves_finished


func _ready():
	assert(parent_spawner_node != null)
	assert(mob_spawner_index < len(mob_spawners))
	
	wave_count = randi_range(min_wave_count, max_wave_count)
	
	for i in range(len(mob_spawners)):
		var mob_spawner: PackedSceneSpawner = mob_spawners[i]
		mob_spawner.on_spawning_finished.connect(on_wave_spawning_finished)
		mob_spawner.spawn_delay_timer.wait_time = enemy_wave_spawn_delay

	
func _process(delta: float):
	if wave_state == WaveState.FINISHED:
		# go to the next wave when all enemies for the current wave are defeated
		if parent_spawner_node.get_child_count() == 0 and wave_index < wave_count:
			wave_state = WaveState.IDLE
			start_spawning_wave()
		# start spawning mobs in the next area
		elif parent_spawner_node.get_child_count() == 0 and wave_index >= wave_count and mob_spawner_index < len(mob_spawners):
			mob_spawner_index += 1
			wave_index = 0
			wave_count = randi_range(min_wave_count, max_wave_count)
			wave_state = WaveState.IDLE
			on_all_waves_finished.emit()

func on_wave_spawning_finished():
	wave_state = WaveState.FINISHED
	wave_index += 1
	
func start_spawning_wave():
	assert(mob_spawner_index < len(mob_spawners))
	wave_state = WaveState.SPAWNING
	enemies_per_wave = randi_range(min_enemies_to_spawn_per_wave, max_enemies_to_spawn_per_wave)
	print("enemies to spawn per wave: ", enemies_per_wave)
	mob_spawners[mob_spawner_index].start_spawning(enemies_per_wave)
