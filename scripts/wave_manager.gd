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

# Used to determine when to randomly spawn bomb pickups for a given room
@export var bomb_ui_picker_view: BombUIPickerView
@export var bomb_pickups_spawners: Array[PackedSceneSpawner] = []
@export var bomb_pickups_spawn_index: int = 0

@export var min_bomb_type_count: int = 2
@export var max_bomb_type_count: int = 4
@export var curr_bomb_type_count: int = 2

@export var bomb_pickup_spawn_delay: float = 0.1 # seconds

# used to determine how long to wait in seconds if bomb pickups should spawn or not
@export var bomb_pickups_spawn_chance_delay: float = 8.0 # seconds
@onready var bomb_pickups_spawn_chance_timer: Timer = $BombPickupsSpawnChanceTimer

signal on_all_waves_finished


func _ready():
	assert(parent_spawner_node != null)
	assert(mob_spawner_index < len(mob_spawners))
	assert(bomb_ui_picker_view != null)
	
	wave_count = randi_range(min_wave_count, max_wave_count)
	curr_bomb_type_count = randi_range(min_bomb_type_count, max_bomb_type_count)
	
	for mob_spawner in mob_spawners:
		mob_spawner.on_spawning_finished.connect(on_wave_spawning_finished)
		mob_spawner.spawn_delay_timer.wait_time = enemy_wave_spawn_delay
		
	for bomb_pickups_spawner in bomb_pickups_spawners:
		bomb_pickups_spawner.spawn_delay_timer.wait_time = bomb_pickup_spawn_delay

	bomb_pickups_spawn_chance_timer.wait_time = bomb_pickups_spawn_chance_delay
	bomb_pickups_spawn_chance_timer.timeout.connect(check_if_bomb_pickups_should_spawn)

func _process(_delta: float):
	if wave_state == WaveState.FINISHED:
		var are_all_wave_enemies_defeated: bool = parent_spawner_node.get_child_count() == 0
		# go to the next wave when all enemies for the current wave are defeated
		if are_all_wave_enemies_defeated and wave_index < wave_count:
			wave_state = WaveState.IDLE
			start_spawning_wave()
		# start spawning mobs in the next area
		elif are_all_wave_enemies_defeated and wave_index >= wave_count and mob_spawner_index < len(mob_spawners):
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

func start_bomb_pickup_chance_timer():
	bomb_pickups_spawn_chance_timer.start()
	
func stop_bomb_pickup_chance_timer():
	if bomb_pickups_spawn_index >= len(bomb_pickups_spawners):
		return
		
	bomb_pickups_spawn_chance_timer.stop()
	bomb_pickups_spawners[bomb_pickups_spawn_index].stop_spawning()

func check_if_bomb_pickups_should_spawn():
	var total_bomb_count: int = bomb_ui_picker_view.get_bomb_count()
	# the less the bombs the player has, the more likely it is to spawn randomized bomb pickups
	# the more bombs the player , the least likely it is to spawn randomized bomb pickups
	var decay_rate: float = 0.025 # higher number means the chances of getting bomb pickup spawns is reduced - lower number means its more likely to get bomb pickup spawns
	var ratio: float = (1.0 / exp(total_bomb_count * decay_rate))
	var chance_pick: float = randf()
	if chance_pick <= ratio:
		spawn_bomb_pickups()

func spawn_bomb_pickups():
	assert(bomb_pickups_spawn_index < len(bomb_pickups_spawners))
	curr_bomb_type_count = randi_range(min_bomb_type_count, max_bomb_type_count)
	print("bomb pickup types to spawn: ", curr_bomb_type_count)
	bomb_pickups_spawners[bomb_pickups_spawn_index].start_spawning(curr_bomb_type_count)
