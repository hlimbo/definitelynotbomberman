class_name DamageText extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $Label

func _ready():
	animation_player.animation_finished.connect(destroy_self)
	# compute pivot to ensure text scales along the center
	label.pivot_offset = Vector2(label.size.x, label.size.y) * 0.5

func play_animation(dmg: float = 0.0):
	label.text = "%d" % int(dmg)
	animation_player.play(&"damage_text")
	
func destroy_self(anim_name: StringName):
	queue_free()
