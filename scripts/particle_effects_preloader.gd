# ParticleEffectsPreloader
# loads all particle effects used in the game at the very beginning
# it is a workaround to avoid lag spikes from occuring in the game for web due to a game engine webgl thing
# See: https://github.com/godotengine/godot/issues/87843
extends Node2D

@export var particle_effects: Array[ParticleProcessMaterial] = []
@export var particle_effect_loaded_count: int = 0
@export var particle_effects_count: int = 0
@export var loading_progress: float = 0.0

func _ready():
	particle_effects_count = len(particle_effects)
	load_particle_effects()
	
func _process(_delta: float):
	if particle_effects_count == 0:
		toggle_processing(false)
		return
		
	loading_progress = float(particle_effect_loaded_count) / float(particle_effects_count)
	if loading_progress >= 1.0:
		toggle_processing(false)

func load_particle_effects():
	for effect in particle_effects:
		var particle_effect = GPUParticles2D.new()
		particle_effect.finished.connect(on_finished_loading_particle_effect, ConnectFlags.CONNECT_ONE_SHOT)
		particle_effect.set_process_material(effect)
		# by default particle effects emitting is set to true
		# set to false before playing them so that the finished signal can be caught by the
		# function callback properly
		particle_effect.emitting = false
		particle_effect.one_shot = true
		particle_effect.emitting = true
		particle_effect.modulate = Color(1.0, 1.0, 1.0, 0.0)
		self.add_child(particle_effect)

func on_finished_loading_particle_effect():
	particle_effect_loaded_count += 1

func toggle_processing(is_processing: bool):
	set_process(is_processing)
	set_physics_process(is_processing)
