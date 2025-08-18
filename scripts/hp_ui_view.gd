class_name HpUiView extends Control

### dependencies
var event_bus: EventBus = EventBus

@onready var damage_progress: TextureProgressBar = $Damage_Progress
@onready var hp_progress: TextureProgressBar = $HP_Progress
@onready var current_hp_label: Label = $HP_Label_Container/CurrentHP
@onready var max_hp_label: Label = $HP_Label_Container/MaxHP

@export var _current_hp: float = 0.0
@export var _max_hp: float = 0.0

# amount of time to reduce hp bar
@export var min_tween_duration_seconds: float = 0.25
@export var max_tween_duration_seconds: float = 0.35

# Used to identify who owns this view and to set the correct hp bar values with
# whenever the event bus emits an event to initialize or update the hp bar values
@export var actor_node: Node2D

func set_actor_node(node: Node2D):
	actor_node = node

func _ready():
	event_bus.on_initialize_hp.connect(initialize)
	event_bus.on_hp_updated.connect(deduct_hp)

func initialize(owner_id: int, current_hp: float, max_hp: float):
	# for some reason this assertion fails when spawning enemies during runtime rather
	# than hand placing them in a scene... and when I do a null check
	# it seems to fix itself....
	# it could be that the enemies and player that spawn in their own hp ui view node
	# is receiving the signal on_initialize_hp from the event bus when some of them don't
	# have the actor_node reference set yet...
	assert(actor_node != null and is_instance_valid(actor_node))
	#if actor_node == null or !is_instance_valid(actor_node):
		#return
	if owner_id != actor_node.get_canvas_item().get_id():
		return
	
	set_hp(current_hp)
	set_max_hp(max_hp)
	var ratio: float = current_hp / max_hp
	set_progress_values(ratio)
	
func deduct_hp(owner_id: int, damage: float):
	# silent error?
	if actor_node == null or !is_instance_valid(actor_node):
		return
	
	if owner_id != actor_node.get_canvas_item().get_id():
		return
	
	var new_hp: float = maxf(_current_hp - damage, 0.0)
	# interpolate from current to new_hp
	var hp_tween: Tween = create_tween()
	var target_ratio: float = new_hp / _max_hp
	
	# the lower the damage, the faster the damage progress tweens
	# the higher the damage, the slower the damage progress tweens
	var max_damage_ratio: float = damage / _max_hp
	var damage_duration: float = (max_tween_duration_seconds - min_tween_duration_seconds) * max_damage_ratio + min_tween_duration_seconds
	
	hp_tween.tween_property(hp_progress, "value", target_ratio * hp_progress.max_value, min_tween_duration_seconds)
	hp_tween.tween_property(damage_progress, "value", target_ratio * damage_progress.max_value, damage_duration)
	self.set_hp(new_hp)
	
	hp_tween.finished.connect(set_progress_values.bind(target_ratio))
	
func set_hp(hp: float):
	_current_hp = hp
	current_hp_label.text = "%d" % int(hp)
	
func set_max_hp(hp: float):
	_max_hp = hp
	max_hp_label.text = "%d" % int(hp)
	
func set_progress_values(ratio: float):
	hp_progress.value = ratio * hp_progress.max_value
	damage_progress.value = ratio * damage_progress.max_value
