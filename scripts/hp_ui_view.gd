extends Control

### dependencies
var event_bus: EventBus = EventBus

@onready var damage_progress: TextureProgressBar = $Damage_Progress
@onready var hp_progress: TextureProgressBar = $HP_Progress
@onready var current_hp_label: Label = $HP_Label_Container/CurrentHP
@onready var max_hp_label: Label = $HP_Label_Container/MaxHP

@onready var deduct_button: Button = $DeductButton
@onready var reset_button: Button = $ResetButton

@export var current_hp: float = 0.0
@export var max_hp: float = 0.0

# amount of time to reduce hp bar
@export var min_tween_duration_seconds: float = 0.25
@export var max_tween_duration_seconds: float = 0.35

func initialize(current_hp: float, max_hp: float):
	set_hp(current_hp)
	set_max_hp(max_hp)
	var ratio: float = current_hp / max_hp
	set_progress_values(ratio)

func _ready():
	event_bus.on_start_attack.connect(on_update_hp)
	initialize(current_hp, max_hp)
	
	deduct_button.pressed.connect(func():
		var damage: float = randf_range(1.0, current_hp)
		self.deduct_hp(damage)
	)
	
	reset_button.pressed.connect(func():
		self.set_hp(max_hp)
		self.set_progress_values(1.0)
	)
	
func on_update_hp(enemy: BaseEnemy, target: Node2D):
	pass
	
func deduct_hp(damage: float):
	var new_hp: float = maxf(current_hp - damage, 0.0)
	# interpolate from current to new_hp
	var hp_tween: Tween = create_tween()
	var hp_tween_duration_seconds: float = 0.25
	var target_ratio: float = new_hp / max_hp
	
	# the lower the damage, the faster the damage progress tweens
	# the higher the damage, the slower the damage progress tweens
	var max_damage_ratio: float = damage / max_hp
	var damage_duration: float = (max_tween_duration_seconds - min_tween_duration_seconds) * max_damage_ratio + min_tween_duration_seconds
	
	hp_tween.tween_property(hp_progress, "value", target_ratio * hp_progress.max_value, min_tween_duration_seconds)
	hp_tween.tween_property(damage_progress, "value", target_ratio * damage_progress.max_value, damage_duration)
	self.set_hp(new_hp)
	
	hp_tween.finished.connect(set_progress_values.bind(target_ratio))
	
func set_hp(hp: float):
	current_hp = hp
	current_hp_label.text = "%d" % int(hp)
	
func set_max_hp(hp: float):
	max_hp = hp
	max_hp_label.text = "%d" % int(hp)
	
func set_progress_values(ratio: float):
	hp_progress.value = ratio * hp_progress.max_value
	damage_progress.value = ratio * damage_progress.max_value
