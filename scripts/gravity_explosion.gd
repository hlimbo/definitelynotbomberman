class_name GravityExplosion extends BaseExplosion

@export var max_pull_force: float = 2000
@export var pull_force_per_physics_step: float = 500
@export var pull_decay: float = 0.25
@export var gravity_radius: float = 0.0

func _ready():
	super()
	var circle: CircleShape2D = collision_shape_2d.shape as CircleShape2D
	gravity_radius = circle.radius
