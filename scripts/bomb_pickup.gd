class_name BombPickup extends Node2D

@export var event_bus: EventBus = EventBus
@onready var pickup_area: Area2D = $PickupArea

@export var bomb_type: Constants.BombType = Constants.BombType.DEFAULT
@export var move_speed: float = 500.0

var is_moving_to_target: bool = false
var can_safely_delete_self: bool = false
var target: Node2D

func _ready():
	pickup_area.body_entered.connect(on_body_entered)

# improvement: use different collision bodies e.g. Area2Ds to determine when a pick up has occurred
# using player's rigidbody's collision is a capsule and needs to be a circle as detecting when grabbing the bomb on the sides is alot narrower than the top and bottom sides of the player
func on_body_entered(body: Node2D):
	if body is Player:
		target = body
		is_moving_to_target = true
		var shrink_tween: Tween = create_tween()
		shrink_tween.tween_property($BombSprite, "scale", Vector2(0.02, 0.02), 0.25)
		shrink_tween.tween_callback(on_shrink_tween_finished)

func move_to_target(body: Node2D, delta: float):
	var diff: Vector2 = body.position - position
	var dir: Vector2 = diff.normalized()
	self.position = position + dir * move_speed * delta
	
	var player = body as Player
	assert(player != null)
	if diff.length() <= player.get_collision_shape().radius:
		var count: int = get_random_bomb_pickup_count(bomb_type)
		event_bus.on_bomb_picked_up.emit(bomb_type, count)
		is_moving_to_target = false
	
func _process(delta: float):
	if is_moving_to_target:
		move_to_target(target, delta)
	elif can_safely_delete_self and !self.is_queued_for_deletion():
		queue_free()

func on_shrink_tween_finished():
	can_safely_delete_self = true
	
func get_random_bomb_pickup_count(_bomb_type: Constants.BombType) -> int:
	var count: int = 1
	match _bomb_type:
		Constants.BombType.GOO:
			count = randi_range(1,2)
		Constants.BombType.ROOT:
			count = randi_range(2,4)
		Constants.BombType.POISON:
			count = randi_range(1,6)
		Constants.BombType.GRAVITY:
			count = randi_range(1,2)
		
	return count
