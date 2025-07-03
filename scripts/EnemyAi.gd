# enemy_ai.gd
extends CharacterBody2D

# Enemy AI script for Godot 4 (2D)
#
# Exported properties:
#   speed            - Movement speed in pixels/second.
#   detection_radius - Radius within which the enemy will chase the player.
#   player_path      - Drag the Player node here in the inspector.
#
# Behavior:
#   - Idle until the player enters detection_radius.
#   - Moves toward the player at the given speed.
#   - Exposes move_direction so animations can react to movement.

@export var speed: float = 120.0
@export var detection_radius: float = 200.0
@export_node_path("Node2D") var player_path: NodePath

var move_direction: Vector2 = Vector2.ZERO
var player: Node2D

func _ready() -> void:
	if player_path != NodePath():
		player = get_node(player_path)

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() <= detection_radius:
		move_direction = to_player.normalized()
		velocity = move_direction * speed
	else:
		move_direction = Vector2.ZERO
		velocity = Vector2.ZERO

	move_and_slide()

func _draw() -> void:
	# Draw detection radius for debugging (editor only)
	draw_circle(Vector2.ZERO, detection_radius, Color(1, 0, 0, 0.25))
