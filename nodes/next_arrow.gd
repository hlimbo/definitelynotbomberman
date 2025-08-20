class_name NextArrow extends Node2D

@export var shader_mat: ShaderMaterial = preload("res://nodes/NextArrowShaderMaterial.tres")


func toggle_shader_mat(toggle: bool):
	if toggle:
		self.material = shader_mat
	else:
		self.material = null
