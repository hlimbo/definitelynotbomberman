class_name RoomManager extends Node

@export var event_bus: EventBus = EventBus

@export var wave_manager: WaveManager
@export var room_index: int = 0
@export var room_triggers: Array[RoomTrigger] = []

func _ready():
	for room_trigger in room_triggers:
		room_trigger.on_enter_room.connect(on_enter_room)
	
	assert(wave_manager != null)
	wave_manager.on_all_waves_finished.connect(on_all_waves_finished)

func on_enter_room():
	print("room index: ", room_index)
	# POLISH: add a delay to spawn start spawning enemies
	# spawn as soon as the hazards fully block player from leaving the room
	room_triggers[room_index].enable_hazards()
	wave_manager.start_spawning_wave()
	# a bit hacky -- the first room by design doesn't spawn any bomb pickups as the player
	# isn't introduced to it yet until the 2nd room
	if room_index > 0:
		wave_manager.start_bomb_pickup_chance_timer()

func on_all_waves_finished():
	wave_manager.stop_bomb_pickup_chance_timer()
	if room_index > 0:
		wave_manager.bomb_pickups_spawn_index += 1
	
	room_triggers[room_index].disable_hazards()
	room_index += 1
	
	if room_index >= len(room_triggers):
		event_bus.on_game_end.emit("GameWon")
