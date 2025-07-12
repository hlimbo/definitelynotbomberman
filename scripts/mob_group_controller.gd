class_name MobGroupController extends Node

@onready var mobs: Array[BaseEnemy] = []

func _ready():
	for child in get_children():
		mobs.append(child as BaseEnemy)
		
func set_mobs_active():
	for mob in mobs:
		mob.ai_state = BaseEnemy.AI_State.IDLE
