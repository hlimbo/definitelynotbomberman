class_name RangedEnemy extends BaseEnemy

@onready var range_line: Line2D = $RangeLine
@onready var shoot_timer: Timer = $shoot_timer
@onready var attack_anim_timer: Timer = $attack_anim_timer
var range_dir: Vector2 = Vector2.ZERO
var can_shoot: bool = true

@export var projectile_node: PackedScene

func _ready():
	super()
	shoot_timer.timeout.connect(on_refresh_cooldown)
	attack_anim_timer.timeout.connect(on_attack_start)
	
func on_refresh_cooldown():
	can_shoot = true

func on_attack_start():
	var projectile: Projectile = projectile_node.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.launch(position, range_dir)
	
	ai_state = AI_State.FOLLOW
	shoot_timer.start()
	range_line.visible = false
	
#region overridable functions
func start_attack():
	if not can_shoot:
		return
	
	can_shoot = false
	self.velocity = Vector2.ZERO
	ai_state = AI_State.ATTACK
	
	range_dir = (target.position - position).normalized()
	
	# draw range direction preview
	range_line.points = [Vector2.ZERO, range_dir * 64.0]
	range_line.visible = true
	attack_anim_timer.start()
#endregion
