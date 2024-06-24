extends "res://Instantiated Scenes/Body 3D/body_3d.gd"

func initialize(radius: float, color: Color, overlay_shader_resource = null):
	set("radius", radius)
	set("height", radius * 2)
	
	#color and shaders probby have to be applued differently
	
	#var material = StandardMaterial3D.new()
	#material.albedo_color = color
	#material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	#if overlay_shader_resource != null:
		#var shader = ShaderMaterial.new()
		#shader.set_shader(overlay_shader_resource)
		#material.next_pass = shader
	#set_surface_override_material(0, material)
	pass
