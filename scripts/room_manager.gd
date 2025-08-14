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

func on_all_waves_finished():
	room_triggers[room_index].disable_hazards()
	room_index += 1
	
	if room_index >= len(room_triggers):
		event_bus.on_game_end.emit("GameWon")
