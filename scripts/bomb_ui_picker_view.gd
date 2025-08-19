class_name BombUIPickerView extends Control

# it would be better if this was its own script that inherited from
# Resource class so that it can be serialized and viewed in the editor if need be
class BombUIData:
	var name: String
	var color: Color
	var count: int
	# represents how many bombs gained/lost by the player
	var count_delta: int
	
	# count of 999 represents infinity
	func _init(_name: String = "default bomb", _color: Color = Color.WHITE, _count: int = 999):
		self.name = _name
		self.color = _color
		self.count = _count
		self.count_delta = 0

### dependencies
@export var event_bus: EventBus = EventBus

@onready var bomb_texture: TextureRect = $BombTexture
@onready var up_arrow_button: TextureButton = $ArrowsContainer/UpArrowButton
@onready var down_arrow_button: TextureButton = $ArrowsContainer/DownArrowButton
@onready var counter_label: Label = $CounterLabel
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var can_animate_bomb_text: bool = false
var curr_animation_time: float = 0.0
var text_update_delay: float = 0.0
@export var text_animation_duration: float = 0.75

@export var view_index: int = 0
const DEFAULT_BOMB_INDEX: int = 0
var bomb_inventory: Array[BombUIData] = [
	BombUIData.new(), # default bomb
	BombUIData.new("poison bomb", Color.VIOLET, 0),
	BombUIData.new("gravity bomb", Color.DARK_SLATE_BLUE, 0),
	BombUIData.new("goo bomb", Color.GREEN, 0),
	BombUIData.new("root bomb",  Color.GOLDENROD, 0)
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

func _process(delta: float):
	if can_animate_bomb_text:
		if curr_animation_time >= text_update_delay:
			curr_animation_time = 0
			
			if bomb_inventory[view_index].count_delta > 0:
				bomb_inventory[view_index].count += 1
				bomb_inventory[view_index].count_delta -= 1
			elif bomb_inventory[view_index].count_delta < 0:
				bomb_inventory[view_index].count -= 1
				bomb_inventory[view_index].count_delta += 1
		
			update_bomb_count_by_index(view_index)
		else:
			curr_animation_time += delta
		if bomb_inventory[view_index].count_delta == 0:
			can_animate_bomb_text = false
	

func view_next_bomb(is_arrow_up: bool):
	# get bomb types count
	var bomb_types_count: int = 0
	for i in range(len(bomb_inventory)):
		if bomb_inventory[i].count > 0:
			bomb_types_count += 1
	
	# default/base bomb only
	if bomb_types_count == 1:
		return
	
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

func set_bomb_type(_view_index: int):
	self.view_index = _view_index
	bomb_texture.modulate = bomb_inventory[view_index].color
	counter_label.text = "%d" % bomb_inventory[view_index].count
	
	if self.view_index == DEFAULT_BOMB_INDEX:
		toggle_text_counter(false)
	else:
		toggle_text_counter(true)

func on_bomb_picked_up(bomb_type: Constants.BombType, count: int):
	var bomb_index: int = int(bomb_type)
	assert(count > 0)
	assert(bomb_index >= 0 and bomb_index < Constants.BombType.LENGTH)
	
	print("count: %d" % count)
	
	# edge case - if 2 bomb pickups of different types are close to one another
	# then immediately update the count of the previous bomb index to ensure data consistency
	if bomb_inventory[view_index].count_delta != 0:
		bomb_inventory[view_index].count += bomb_inventory[view_index].count_delta
		bomb_inventory[view_index].count_delta = 0
	
	set_bomb_type(bomb_index)
	bomb_inventory[bomb_index].count_delta += count
	can_animate_bomb_text = true
	curr_animation_time = 0
	text_update_delay = text_animation_duration / count
	event_bus.on_player_bomb_switched.emit(bomb_index)

func on_bomb_thrown(bomb_type: Constants.BombType):
	# infinite default bombs
	if bomb_type == Constants.BombType.DEFAULT:
		return
	
	var bomb_index: int = int(bomb_type)
	assert(bomb_index >= 0 and bomb_index < Constants.BombType.LENGTH)
	bomb_inventory[bomb_index].count = maxi(bomb_inventory[bomb_index].count - 1, 0)
	update_bomb_count_by_index(bomb_index)
	
	# go to the next bomb that has ammo left... by default it will go to the Base Bomb
	# as it should have infinite ammo
	while bomb_inventory[bomb_index].count == 0:
		bomb_index = (bomb_index + 1) % Constants.BombType.LENGTH
	
	set_bomb_type(bomb_index)
	event_bus.on_player_bomb_switched.emit(bomb_index)
	
func update_bomb_count_by_index(index: int):
	if index == view_index:
		counter_label.text = "%d" % bomb_inventory[view_index].count
		
func toggle_text_counter(_is_visible: bool):
	counter_label.visible = _is_visible
	
func get_bomb_count() -> int:
	var total: int = 0
	# start at index 1 because index 0 is default bomb with infinite count
	for i in range(1, len(bomb_inventory)):
		total += bomb_inventory[i].count

	return total
