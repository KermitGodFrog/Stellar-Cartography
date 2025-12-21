@tool
extends MeshInstance3D

func _process(delta):
	var material : ShaderMaterial = get_active_material(0)
	var noise = material.get_shader_parameter("noise")
	noise.get_noise().offset.x -= (PI * delta)
	var normal_map = material.get_shader_parameter("normal_map")
	normal_map.get_noise().offset.x -= (PI * delta)
	
	material.set_shader_parameter("noise", noise)
	material.set_shader_parameter("normal_map", noise)
	pass
