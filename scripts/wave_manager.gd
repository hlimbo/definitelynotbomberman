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

@export var min_wave_count: int = 2
@export var max_wave_count: int = 3
@export var min_enemies_to_spawn_per_wave: int = 2
@export var max_enemies_to_spawn_per_wave: int = 6

@export var wave_index: int = 0
@export var wave_count: int = 1
@export var enemies_per_wave: int = 2
@export var enemy_wave_spawn_delay: float = 0.25 # seconds

@export var wave_state: WaveState = WaveState.START


func _ready():
	assert(len(mob_spawners) == wave_count)
	
	# wave_count = randi_range(min_wave_count, max_wave_count)
	
	for i in range(wave_count):
		var mob_spawner: PackedSceneSpawner = mob_spawners[i]
		mob_spawner.on_spawning_finished.connect(on_wave_spawning_finished)
		mob_spawner.spawn_delay_timer.wait_time = enemy_wave_spawn_delay
		
	event_bus.on_game_start.connect(on_game_start)

	
func _process(delta: float):
	if wave_state == WaveState.IDLE:
		start_spawning_wave()
	elif wave_state == WaveState.FINISHED:
		if wave_index < wave_count:
			wave_state = WaveState.IDLE

func on_wave_spawning_finished():
	wave_state = WaveState.FINISHED
	wave_index += 1
	
	if wave_index < wave_count:
		enemies_per_wave = randi_range(min_enemies_to_spawn_per_wave, max_enemies_to_spawn_per_wave)
		mob_spawners[wave_index].spawn_count = enemies_per_wave
		
func on_game_start():
	start_spawning_wave()
	
func start_spawning_wave():
	assert(wave_index < wave_count)
	wave_state = WaveState.SPAWNING
	mob_spawners[wave_index].start_spawning()
