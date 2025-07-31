class_name WeightTable extends Resource

# key represents what can be spawned in a scene
# value represents the weight of the PackedScene. Used to determine the likelihood of spawning the PackedScene.
# higher weight values means higher likelihood of spawning. lower weight values means lower likelihood of spawning.
@export var original_pool: Dictionary[PackedScene, float] = {}
# represents what can be randomly spawned
var active_pool: Dictionary[PackedScene, float] = {}
# represents what isn't available to be randomly spawned
var inactive_pool: Dictionary[PackedScene, bool] = {}

# used to determine if only unique picks are required
@export var is_unique_only: bool = false

var sum_weights: float = 0.0

func construct():
	for packed_scene in original_pool:
		active_pool[packed_scene] = original_pool[packed_scene]
		inactive_pool[packed_scene] = false
		
	sum_weights = compute_sum_weights()

func compute_sum_weights() -> float:
	var weights_sum: float = 0.0
	for packed_scene in active_pool:
		var weight: float = active_pool[packed_scene]
		weights_sum += weight

	return weights_sum
	
func pick_random_spawnable() -> PackedScene:
	assert(len(active_pool) > 0)
	var packed_scene: PackedScene = active_pool.keys()[len(active_pool) - 1] as PackedScene
	
	var random_val: float = randf() * sum_weights
	var total_weight: float = 0.0
	# using linear scan algorithm... there exists alternatives like binary search or hopscotch
	# but for a game with a few choices linear scan is easiest to implement and least error prone
	for scene in active_pool:
		var weight: float = active_pool[scene]
		total_weight += weight
		if total_weight > random_val:
			packed_scene = scene
			break
	
	# remove from active pool to ensure unique scenes are picked
	if is_unique_only:
		remove_packed_scene_from_active_pool(packed_scene)
		
	return packed_scene

func remove_packed_scene_from_active_pool(scene: PackedScene) -> bool:
	var is_erased: bool = active_pool.erase(scene)
	if is_erased:
		# mark scene as inactive
		inactive_pool[scene] = true
		var weight: float = original_pool[scene]
		sum_weights -= weight
	
	return is_erased
	
func add_packed_scene_to_active_pool(scene: PackedScene) -> bool:
	assert(scene in original_pool)
	if scene in inactive_pool and inactive_pool[scene]:
		# mark scene as active
		inactive_pool[scene] = false
		active_pool[scene] = original_pool[scene]
		var weight: float = original_pool[scene]
		sum_weights += weight
		return true
	
	return false
