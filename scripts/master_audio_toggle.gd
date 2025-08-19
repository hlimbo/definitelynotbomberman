# only useful for web builds as audio by default doesn't play unless you click on the screen at least once...
extends TextureButton

@export var event_bus: EventBus = EventBus
@export var menu_music: AudioStreamPlayer

@onready var label: Label = $Label
@onready var sfx_sound: AudioStreamPlayer = $AudioStreamPlayer

# master audio bus name from default_audio_bus_layout.tres
const MASTER: StringName = &"Master"
var master_index: int = -1


func _ready():
	master_index = AudioServer.get_bus_index(MASTER)
	assert(master_index != -1)
	assert(menu_music != null)
	self.pressed.connect(on_toggle)
	
	event_bus.on_mute_setting_changed.connect(_on_mute_setting_changed)
	
	# check which platform this build is on
	if OS.get_name() == "Web":
		set_audio_toggle(false)
	else:
		set_audio_toggle(true)
		menu_music.play()
		
	event_bus.on_mute_setting_changed.emit()

func on_toggle():
	# toggle between mute and not muted audio
	var is_audio_playing: bool = AudioServer.is_bus_mute(master_index)
	set_audio_toggle(is_audio_playing)
	event_bus.on_mute_setting_changed.emit()
	
	if is_audio_playing:
		sfx_sound.play()

func set_audio_toggle(toggle: bool):
	if toggle:
		AudioServer.set_bus_mute(master_index, false)
	else:
		AudioServer.set_bus_mute(master_index, true)

func _on_mute_setting_changed():
	var is_audio_playing: bool = !AudioServer.is_bus_mute(master_index)
	if is_audio_playing:
		label.text = "Audio - On"
	else:
		label.text = "Audio - Off"
