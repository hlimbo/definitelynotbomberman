class_name DashingEnemy extends BaseEnemy

@onready var dash_attack_timer: Timer = $dash_attack_timer
@onready var cooldown_timer: Timer = $cooldown_timer
@onready var attack_area: Area2D = $AttackArea
@onready var dash_line: Line2D = $DashLine
@onready var dash_audio_player: AudioStreamPlayer2D = $dash_audio_player

@export var dash_attack_distance: float = 90.0 # units
# measured in milliseconds
@export var dash_attack_duration: int = 3000
@export var max_dash_velocity: float = 1000.0
@export var dash_acceleration: float = 100.0

var start_dash_position: Vector2 = Vector2.ZERO
var dash_dir: Vector2 = Vector2.ZERO
var can_dash: bool = true
# measured in milliseconds
var start_dash_duration: int = 0
var curr_dash_duration: int = 0

func _ready():
	super()
	dash_attack_timer.timeout.connect(start_dash_attack)
	cooldown_timer.timeout.connect(on_refresh_cooldown)
	attack_area.body_entered.connect(on_dash_attack_connected)
	
func on_dash_attack_connected(other: Node2D):
	if other is not Player:
		return
	
	event_bus.on_start_attack.emit(self, other)
	complete_dash()
	
func start_dash_attack():
	if ai_state == AI_State.ATTACK:
		return
		
	ai_state = AI_State.ATTACK
	dash_audio_player.play()

func on_refresh_cooldown():
	can_dash = true

func complete_dash():
	self.velocity = Vector2(0.0, 0.0)
	dash_line.visible = false
	ai_state = AI_State.FOLLOW
	cooldown_timer.start()

#region overridable functions
func disable():
	super()
	can_dash = false
	dash_line.visible = false
	dash_attack_timer.stop()
	cooldown_timer.stop()

func interrupt():
	can_dash = true
	dash_attack_timer.stop()
	cooldown_timer.stop()
	dash_line.visible = false

func handle_states():
	super()
	
	if ai_state == AI_State.ATTACK:
		var velocity_a: Vector2 = velocity + dash_dir * dash_acceleration
		var velocity_b: Vector2 = dash_dir * max_dash_velocity
		if velocity_a.length_squared() > velocity_b.length_squared():
			self.velocity = velocity_b
		else:
			self.velocity = velocity_a
		
		var curr_dash_distance: float = start_dash_position.distance_to(position)
		
		curr_dash_duration = Time.get_ticks_msec() - start_dash_duration
		# if reached or exceeded dash attack distance switch back to follow state
		if curr_dash_distance >= dash_attack_distance or curr_dash_duration >= dash_attack_duration:
			complete_dash()

func start_attack():
	# if dash attack on cooldown, don't dash
	if not can_dash and [AI_State.HURT, AI_State.DEATH].has(ai_state):
		return
	
	ai_state = AI_State.PREP_ATTACK
	can_dash = false
	curr_dash_duration = 0
	start_dash_duration = Time.get_ticks_msec()
	
	# draw preview of where dash will move towards using Line2D node
	dash_dir = (target.position - position).normalized()
	var dash_preview_vector: Vector2 = dash_dir * dash_attack_distance
	dash_line.points = [Vector2.ZERO, dash_preview_vector]
	dash_line.visible = true
	
	velocity = Vector2.ZERO
	start_dash_position = position
	dash_attack_timer.start()
#endregion
