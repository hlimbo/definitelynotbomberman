class_name ClockHUD extends Label

const SECONDS_TO_MINUTES: int = 60

@export var event_bus: EventBus = EventBus
@onready var timer: Timer = $Timer

@export var start_time_seconds: int = 345
var _curr_time: int = 0

func convert_to_minutes_seconds(curr_time: int) -> String:
	var minutes: int = curr_time / SECONDS_TO_MINUTES
	var seconds: int = curr_time % SECONDS_TO_MINUTES
	
	return "%02d:%02d" % [minutes, seconds] 
	
func _ready():
	_curr_time = start_time_seconds
	timer.timeout.connect(on_time_elapsed)
	self.text = convert_to_minutes_seconds(_curr_time)

func start_countdown():
	timer.start()

func on_time_elapsed():
	_curr_time = max(_curr_time - 1, 0)
	
	self.text = convert_to_minutes_seconds(_curr_time)
	
	if _curr_time == 0:
		timer.stop()
		event_bus.on_game_end.emit("GameWon")
