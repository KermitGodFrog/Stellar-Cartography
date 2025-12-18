extends MeshInstance3D

var identifier: int

func get_identifier():
	return identifier

func set_identifier(new_identifier: int):
	identifier = new_identifier
	pass

func initialize(radius: float, color: Color, emission_color: Color, emission_multiplier: float, overlay_shader_resource = null, surface_texture = null):
	set("radius", radius)
	set("height", radius * 2)
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = emission_multiplier
	if surface_texture != null:
		material.emission_texture = surface_texture
	if overlay_shader_resource != null:
		var shader = ShaderMaterial.new()
		shader.set_shader(overlay_shader_resource)
		material.next_pass = shader
	set_surface_override_material(0, material)
	pass

func updatePosition(pos: Vector3):
	position = pos
	pass
