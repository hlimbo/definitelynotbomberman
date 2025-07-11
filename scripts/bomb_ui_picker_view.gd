extends Control

# it would be better if this was its own script that inherited from
# Resource class so that it can be serialized and viewed in the editor if need be
class BombUIData:
	var name: String
	var color: Color
	var count: int
	
	func _init(name: String = "default bomb", color: Color = Color.WHITE, count: int = 999):
		self.name = name
		self.color = color
		self.count = count

### dependencies
@export var event_bus: EventBus = EventBus

@onready var bomb_texture: TextureRect = $BombTexture
@onready var up_arrow_button: TextureButton = $ArrowsContainer/UpArrowButton
@onready var down_arrow_button: TextureButton = $ArrowsContainer/DownArrowButton
@onready var counter_label: Label = $CounterLabel
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@export var view_index = 0
var bomb_inventory: Array[BombUIData] = [
	BombUIData.new(), # default bomb
	BombUIData.new("poison bomb", Color.VIOLET, 20),
	BombUIData.new("gravity bomb", Color.DARK_SLATE_BLUE, 40),
	BombUIData.new("goo bomb", Color.GREEN, 60),
	BombUIData.new("root bomb",  Color.GOLDENROD, 80)
]

func _ready():
	up_arrow_button.pressed.connect(view_next_bomb.bind(true))
	down_arrow_button.pressed.connect(view_next_bomb.bind(false))
	set_bomb_type(view_index)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			view_next_bomb(true)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			view_next_bomb(false)

func view_next_bomb(is_arrow_up: bool):
	var direction: int = -1 if is_arrow_up else 1
	view_index = (view_index + direction) % len(bomb_inventory)
	if view_index < 0:
		view_index = len(bomb_inventory) - 1
	
	set_bomb_type(view_index)
	event_bus.on_bomb_switched.emit(view_index)
	audio_stream_player.play()

func set_bomb_type(view_index: int):
	print("bomb type: %s" % bomb_inventory[view_index].name)
	bomb_texture.modulate = bomb_inventory[view_index].color
	counter_label.text = "%d" % bomb_inventory[view_index].count
