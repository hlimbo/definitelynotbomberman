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
	event_bus.on_bomb_picked_up.connect(on_bomb_picked_up)
	event_bus.on_bomb_thrown.connect(on_bomb_thrown)
	
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
	
	# skip to the next bomb that isn't empty -- for now the base bomb (default) will be infinite
	while bomb_inventory[view_index].count == 0:
		view_index = (view_index + direction) % len(bomb_inventory)
		if view_index < 0:
			view_index = len(bomb_inventory) - 1
	
	set_bomb_type(view_index)
	event_bus.on_player_bomb_switched.emit(view_index)
	audio_stream_player.play()

func set_bomb_type(view_index: int):
	print("bomb type: %s" % bomb_inventory[view_index].name)
	bomb_texture.modulate = bomb_inventory[view_index].color
	counter_label.text = "%d" % bomb_inventory[view_index].count

func on_bomb_picked_up(bomb_type: Constants.BombType, count: int):
	var bomb_index: int = int(bomb_type)
	assert(bomb_index >= 0 and bomb_index < Constants.BombType.LENGTH)
	bomb_inventory[bomb_index].count += count
	update_bomb_count_by_index(bomb_index)
	set_bomb_type(bomb_index)
	event_bus.on_player_bomb_switched.emit(bomb_index)

func on_bomb_thrown(bomb_type: Constants.BombType):
	# infinite default bombs
	if bomb_type == Constants.BombType.DEFAULT:
		return
	
	var bomb_index: int = int(bomb_type)
	assert(bomb_index >= 0 and bomb_index < Constants.BombType.LENGTH)
	bomb_inventory[bomb_index].count = maxi(bomb_inventory[bomb_index].count - 1, 0)
	update_bomb_count_by_index(bomb_index)
	
	var is_out_of_bombs: bool = bomb_inventory[bomb_index].count == 0
	
	while bomb_inventory[bomb_index].count == 0:
		set_bomb_type(bomb_index)
		event_bus.on_player_bomb_switched.emit(bomb_index)
	
func update_bomb_count_by_index(index: int):
	if index == view_index:
		counter_label.text = "%d" % bomb_inventory[view_index].count
