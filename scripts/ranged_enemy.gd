class_name RangedEnemy extends BaseEnemy

@onready var range_line: Line2D = $RangeLine
@onready var shoot_timer: Timer = $shoot_timer
@onready var attack_anim_timer: Timer = $attack_anim_timer
var range_dir: Vector2 = Vector2.ZERO
var can_shoot: bool = true

@export var projectile_container: Node2D

@export var projectile_node: PackedScene

func _ready():
	super()
	shoot_timer.timeout.connect(on_refresh_cooldown)
	attack_anim_timer.timeout.connect(on_attack_start)
	var container: Node = self.get_tree().get_first_node_in_group(&"projectile_container")
	projectile_container = container as Node2D
	assert(projectile_container != null)
	
func on_refresh_cooldown():
	can_shoot = true

func on_attack_start():
	var projectile: Projectile = projectile_node.instantiate()
	projectile_container.add_child(projectile)
	projectile.launch(position, range_dir)
	
	ai_state = AI_State.FOLLOW
	shoot_timer.start()
	range_line.visible = false
	
#region overridable functions
func disable():
	super()
	range_line.visible = false
	can_shoot = false
	shoot_timer.stop()
	attack_anim_timer.stop()

func interrupt():
	range_line.visible = false
	can_shoot = true
	shoot_timer.stop()
	attack_anim_timer.stop()

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
