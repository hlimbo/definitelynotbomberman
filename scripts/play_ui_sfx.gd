extends BaseButton

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	self.pressed.connect(on_pressed)
	
func on_pressed():
	audio_stream_player.play()
