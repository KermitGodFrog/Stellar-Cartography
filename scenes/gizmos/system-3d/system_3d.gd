extends Node3D
#system_3d_internal_v2

signal foundBody(id: int)
signal addConsoleEntry(entry_text: String, text_color: Color)

@onready var control = $camera_offset/camera/canvas_layer/control
@onready var camera_offset = $camera_offset
@onready var camera = $camera_offset/camera
@onready var locked_body_label = $camera_offset/camera/canvas_layer/control/locked_body_label
@onready var post_process = $camera_offset/camera/canvas_layer/post_process
@onready var star_omni_light = $star_omni_light
@onready var mode_switch_button = $camera_offset/camera/canvas_layer/control/mode_switch_button
@onready var rad_post_process = $camera_offset/camera/canvas_layer/rad_post_process
@onready var environment = $world_environment

#resources
var actor_3d = preload("uid://drrmba8quj4mu")

#for wormholes obv      <- past me who put this comment, stop being such a fucking smartass istg
var wormhole_shader = preload("uid://bkngs6wdkye6n")
var pulsar_beam_material = preload("uid://dtpqpy1b1rnxv")

var vis_panorama = preload("uid://byp6pykkhwnpf")
var rad_panorama = preload("uid://c7u31smqi45er")

var glint_large_texture = preload("uid://c236x4bwtcifq")
var glint_small_texture = preload("uid://kxo1pkvmhml4")

var circular_body_texture = preload("uid://dmcaf8av01hwx")

var system: starSystemAPI
var player_position: Vector2
var target_position: Vector2
var locked_body_identifier: int
var label_locked_body_identifier: int

var system_scalar: float = 10.0
var body_detection_range: int = 1000
var target_fov: float = 75
var scope_mode: playerAPI.SCOPE_MODES = playerAPI.SCOPE_MODES.VIS:
	set(value):
		scope_mode = value
		_on_scope_mode_changed(value)
func get_scope_mode() -> playerAPI.SCOPE_MODES:
	return scope_mode

var initial_beam_rotation: float = 0.0 #REQUIRED FOR PULSARS TO WORK. BARELY KNEW WHAT I WAS DOING WHEN I MADE IT WORK SO DONT TOUCH!

var actors: Array[actor3D] = []

func _ready():
	mutex = Mutex.new()
	_on_scope_mode_changed(playerAPI.SCOPE_MODES.VIS)
	control.connect("targetFOVChange", _on_target_FOV_change)
	pass

func _physics_process(_delta):
	update_positions()
	update_camera_basis()
	update_miscellaneous()
	try_discover_orbit_bodies()
	pass

func update_positions() -> void: #camera and bodies
	camera_offset.position = Vector3((player_position.x * system_scalar), 0, (player_position.y * system_scalar))
	
	for actor in actors:
		#setting player distance, locking player distance from bodie and moving bodies
		var associated_body = system.get_body_from_identifier(actor.get_identifier())
		if associated_body:
			actor.position = Vector3(associated_body.position.x * system_scalar, 0, associated_body.position.y * system_scalar)
			if not actor.is_in_any_utility_cohorts():
				var min_dist = ((associated_body.radius * system_scalar) * 1.1) + 1.0
				if camera_offset.position.distance_to(actor.position) < min_dist:
					camera_offset.position = actor.position + (actor.position.direction_to(camera_offset.position) * min_dist)
		
		if actor.is_in_cohort(actor3D.COHORTS.AI_UNIT):
			actor.set("_player_position", player_position)
			actor.set("_associated_position", associated_body.position)
		
		#update pulsars
		if actor.is_in_cohort(actor3D.COHORTS.PULSAR_BEAM):
			var beam = actor.mesh_instance as MeshInstance3D
			var star = system.get_first_star()
			
			if star is pulsarBodyAPI:
				var dir = Vector2.UP.rotated(star.beam_rotation - initial_beam_rotation)
				var a = dir + Vector2(0, -1).rotated(star.beam_rotation - initial_beam_rotation)
				var a_3d = Vector3(a.x, 0, a.y) * system_scalar
				
				beam.transform = beam.transform.looking_at(a_3d)
				
				#THIS ACTUALLY WORKS??? THANKS - initial_beam_rotation
		elif actor.is_in_cohort(actor3D.COHORTS.PULSAR_BEAM_SFX):
			var star = system.get_first_star()
			var player_distance = player_position.distance_to(star.position)
			var offset = Vector2(0, -player_distance).rotated(star.beam_rotation)
			#\/ horrible way to do this but i got 4.5 to 5 hours of sleep last night so give me a FUCKING BREAK !!! BITCH !!!
			if actor.is_in_group("pulsar_beam_3d_flyby_sfx_0"):
				actor.set_position(Vector3(offset.x, 0, offset.y) * system_scalar)
			elif actor.is_in_group("pulsar_beam_3d_flyby_sfx_1"):
				actor.set_position(Vector3(-offset.x, 0, -offset.y) * system_scalar)
	pass

func update_camera_basis() -> void:
	#looking at locked body or looking at target position
	if locked_body_identifier:
		var locked_actor: actor3D
		for actor in actors:
			if not actor.is_in_any_utility_cohorts():
				if actor.get_identifier() == locked_body_identifier:
					locked_actor = actor
		if locked_actor and target_position == Vector2.ZERO:
			camera.global_transform = camera.global_transform.looking_at(locked_actor.global_transform.origin)
			camera.global_transform = camera.global_transform.orthonormalized()
		elif target_position:
			camera.global_transform = camera.global_transform.looking_at(Vector3((target_position.x * system_scalar), 0, (target_position.y * system_scalar)))
			camera.global_transform = camera.global_transform.orthonormalized()
	elif target_position:
		camera.global_transform = camera.global_transform.looking_at(Vector3((target_position.x * system_scalar), 0, (target_position.y * system_scalar)))
		camera.global_transform = camera.global_transform.orthonormalized()
	pass

func update_miscellaneous() -> void:
	#setting post process
	var fov_to_pixel_size = remap(camera.fov, 10, 75, 8, 2)
	post_process.material.set("shader_parameter/pixel_size", round(fov_to_pixel_size))
	
	camera.fov = lerp(camera.fov, target_fov, 0.05)
	
	#setting locked_body_label text
	var body: bodyAPI = system.get_body_from_identifier(label_locked_body_identifier)
	if body:
		if body.is_known():
			locked_body_label.set_text(str("LOCKED: ", body.get_display_name()))
		elif body.is_theorised_not_known(): #does not need override for unitBodyAPIs as it should clear before this can run
			locked_body_label.set_text("LOCKED: Unknown")
	elif target_position != Vector2.ZERO:
		locked_body_label.set_text("LOCKED: MANUAL")
	else: 
		locked_body_label.set_text("")
	pass

func try_discover_orbit_bodies() -> void:
	for actor in actors:
		if actor.is_in_cohort(actor3D.COHORTS.ORBIT_BODY):
			var a = camera.global_transform.basis.z
			var b = (camera.global_transform.origin - actor.global_transform.origin).normalized() 
			if acos(a.dot(b)) <= deg_to_rad(camera.fov):
				var associated_body = system.get_body_from_identifier(actor.get_identifier()) #repeat code ?!?!?!?!?!?!?!??!?!?!?!?!??!!
				if associated_body:
					if associated_body is orbitBodyAPI:
						if associated_body.get_required_scope_mode() == get_scope_mode():
							var detection_scalar = camera_offset.position.distance_to(actor.position) * camera.fov
							if detection_scalar < body_detection_range and associated_body.is_known() == false:
								if associated_body.is_hidden():
									continue
								
								var star_rarity_multiplier = system.get_first_star_discovery_multiplier()
								if not associated_body.metadata.has("value"): emit_signal("addConsoleEntry", str("DISCOVERED: ", associated_body.get_display_name()), Color.DARK_GREEN)
								elif associated_body.metadata.has("value"): emit_signal("addConsoleEntry", str("DISCOVERED: ", associated_body.get_display_name(), " (est. value ", roundi(associated_body.metadata.get("value") * star_rarity_multiplier), "n) [%.2fx]") % star_rarity_multiplier, Color.DARK_GREEN)
								emit_signal("foundBody", actor.get_identifier())
	pass



var tex_gen_thread: Thread
var exit_tex_gen_thread: bool = false
var mutex: Mutex
func regenerate_system() -> void: #assumes that 'system' is set by game.gd beforehand - which is what happens.
	mutex.lock()
	exit_tex_gen_thread = true
	mutex.unlock()
	
	if tex_gen_thread != null:
		if tex_gen_thread.is_started():
			tex_gen_thread.wait_to_finish()
	
	var tex_gen_pairs: Dictionary = {} # {actor: body}
	
	var remove_actors: Array[actor3D] = []
	remove_actors.append_array(actors)
	for actor in remove_actors:
		actors.erase(actor)
		call_deferred("remove_child", actor)
		actor.queue_free()
	actors.clear()
	remove_actors.clear()
	
	for body in system.bodies:
		
		match body:
			_ when body is circularBodyAPI:
				
				var mesh: SphereMesh
				match body.get_type():
					starSystemAPI.BODY_TYPES.PLANET:
						mesh = generate_circular_body_sphere_mesh(body.radius * system_scalar, system.get_first_star().surface_color, body.surface_color, 0.25, null)
					starSystemAPI.BODY_TYPES.STAR:
						mesh = generate_circular_body_sphere_mesh(body.radius * system_scalar, body.surface_color, body.surface_color, 1.0, null)
						star_omni_light.light_color = body.surface_color
						star_omni_light.light_size = body.radius
						if body is pulsarBodyAPI:
							add_pulsar_beams(body)
					starSystemAPI.BODY_TYPES.WORMHOLE:
						mesh = generate_circular_body_sphere_mesh(body.radius * system_scalar, system.get_first_star().surface_color, body.surface_color, 0.75, wormhole_shader)
				
				var new_actor = await add_actor(
					body.get_identifier(),
					[actor3D.COHORTS.ORBIT_BODY, actor3D.COHORTS.CIRCULAR_BODY], 
					{"mesh": mesh},
					{},
					{},
					{"playing": true}
				)
				
				if body.get_type() in [starSystemAPI.BODY_TYPES.PLANET, starSystemAPI.BODY_TYPES.STAR]:
					tex_gen_pairs[new_actor] = body
				
			_ when body is glintBodyAPI:
				
				add_actor(
					body.get_identifier(), 
					[actor3D.COHORTS.ORBIT_BODY, actor3D.COHORTS.GLINT_BODY]
				)
				
			_ when body is customBodyAPI:
				match body.get_dialogue_tag():
					"SpA_DysonSphere":
						var adj_star_radius = system.get_first_star().radius * system_scalar
						add_actor(
							body.get_identifier(),
							[actor3D.COHORTS.ORBIT_BODY],
							{"mesh": load(body.mesh_path), "material_override": load("uid://cc253avedtu3c"), "scale": Vector3(adj_star_radius, adj_star_radius, adj_star_radius)}
						)
					_:
						if body.mesh_path.is_empty():
							add_actor(
								body.get_identifier(), 
								[actor3D.COHORTS.ORBIT_BODY, actor3D.COHORTS.GLINT_BODY]
							)
						else:
							add_actor(
								body.get_identifier(),
								[actor3D.COHORTS.ORBIT_BODY],
								{"mesh": load(body.mesh_path)}
							)
				
			_ when body is AIUnitAPI:
				
				add_actor(
					body.get_identifier(),
					[actor3D.COHORTS.UNIT_BODY, actor3D.COHORTS.AI_UNIT],
					{},
					{"texture": load("uid://dmi1b3su1mdfw"), "hframes": 4, "pixel_size": starSystemAPI.get_default_radius_solar_radii() * 16.0}, #* 16.0 -> 2x larger than entity_128x.png ('RAD' glint body)
					{},
					{},
					load("uid://bp4kotll44otn")
				)
				
			_ when body is mineUnitAPI:
				
				add_actor(
					body.get_identifier(),
					[actor3D.COHORTS.UNIT_BODY, actor3D.COHORTS.MINE_UNIT],
					{},
					{"texture": load("uid://ckn4a4yoov0cb"), "pixel_size": starSystemAPI.get_default_radius_solar_radii() / 20.0, "modulate": Color("ff7f6e"), "fixed_size": true},
					{},
					{},
					load("uid://dp1qkb1o0tmap")
				)
				
				add_actor(
					body.get_identifier(),
					[actor3D.COHORTS.AUDIO, actor3D.COHORTS.MINE_SFX],
					{},
					{},
					{"stream": load("uid://b7vu4bpvxlu6n"), "attenuation_model": 3, "volume_db": -12.0, "max_db": -12.0} #attenuation model 3 -> ATTENUATION_DISABLED
				)
	
	_on_scope_mode_changed(get_scope_mode()) #to refresh all cohorts which change on scope mode change! dont want to assume we r in VIS mode >:)
	
	exit_tex_gen_thread = false
	tex_gen_thread = Thread.new()
	tex_gen_thread.start(threaded_generate_surface_textures.bind(tex_gen_pairs))
	pass

func add_actor(id: int, cohorts: Array[actor3D.COHORTS], mesh_variables: Dictionary = {}, sprite_variables: Dictionary = {}, audio_variables: Dictionary = {}, flyby_variables: Dictionary = {}, override_script = null) -> Node3D:
	var new_actor = actor_3d.instantiate()
	if override_script != null:
		new_actor.set_script(override_script)
	new_actor.set_identifier(id)
	for c in cohorts:
		new_actor.add_cohort(c)
	add_child(new_actor)
	actors.append(new_actor)
	if not new_actor.is_node_ready():
		await new_actor.ready
		new_actor.initialize(mesh_variables, sprite_variables, audio_variables, flyby_variables)
		return new_actor
	else:
		new_actor.initialize(mesh_variables, sprite_variables, audio_variables, flyby_variables)
		return new_actor

func add_pulsar_beams(_star: pulsarBodyAPI) -> void:
	initial_beam_rotation = _star.beam_rotation
	var points = get_pulsar_beams_as_3D_points(_star)
	
	for beam_points in points:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = beam_points
		
		var arr_mesh = ArrayMesh.new()
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		var new_actor = await add_actor(
			_star.get_identifier(),
			[actor3D.COHORTS.PULSAR_BEAM],
			{"mesh": arr_mesh}
		)
		
		new_actor.mesh_instance.set_surface_override_material(0, pulsar_beam_material)
		
	
	for flyby_sfx in 2:
		var new_actor = await add_actor(
			_star.get_identifier(),
			[actor3D.COHORTS.AUDIO, actor3D.COHORTS.PULSAR_BEAM_SFX],
			{},
			{},
			{},
			{"playing": true, "volume_db": 12.0, "max_distance": 300.0, "unit_size": 25.0, "pitch_scale": 3.0}
		)
		
		new_actor.add_to_group("pulsar_beam_3d_flyby_sfx_%.f" % flyby_sfx)
	pass

func generate_circular_body_sphere_mesh(radius: float, color: Color, emission_color: Color, emission_multiplier: float, overlay_shader_resource = null, surface_texture = null) -> SphereMesh:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = emission_multiplier
	if surface_texture != null:
		material.emission_texture = surface_texture
	if overlay_shader_resource != null:
		var shader_material = ShaderMaterial.new()
		shader_material.set_shader(overlay_shader_resource)
		material.next_pass = shader_material
	mesh.set_material(material)
	return mesh

func threaded_generate_surface_textures(_tex_gen_pairs: Dictionary = {}) -> void:
	for actor in _tex_gen_pairs:
		mutex.lock()
		var should_exit = exit_tex_gen_thread
		mutex.unlock()
		
		if should_exit:
			print("SYSTEM 3D: THREADED SURFACE TEXTURE GENERATION -> EXITED EARLY")
			return
		
		var body = _tex_gen_pairs.get(actor)
		var material = actor.mesh_instance.mesh.material as StandardMaterial3D
		material.set_texture(BaseMaterial3D.TEXTURE_EMISSION, get_surface_texture_for_circular_body(body))
	
	print("SYSTEM 3D: THREADED SURFACE TEXTURE GENERATION -> COMPLETE")
	return







#misc

func reset_locked_body():
	locked_body_identifier = 0
	label_locked_body_identifier = 0
	pass

func _on_target_FOV_change(fov: float):
	target_fov = fov
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "scopes_fov_change")
	pass

func _on_scope_mode_changed(new_mode: playerAPI.SCOPE_MODES) -> void:
	match new_mode:
		playerAPI.SCOPE_MODES.VIS:
			rad_post_process.hide()
			environment.get_environment().get_sky().get_material().set_shader_parameter("source_panorama", vis_panorama)
		playerAPI.SCOPE_MODES.RAD:
			rad_post_process.show()
			environment.get_environment().get_sky().get_material().set_shader_parameter("source_panorama", rad_panorama)
	
	for actor in actors:
		if actor.is_in_cohort(actor3D.COHORTS.CIRCULAR_BODY):
			match new_mode:
				playerAPI.SCOPE_MODES.VIS:
					actor.mesh_instance.set_transparency(0.0)
				playerAPI.SCOPE_MODES.RAD:
					actor.mesh_instance.set_transparency(0.9)
		if actor.is_in_cohort(actor3D.COHORTS.GLINT_BODY):
			match new_mode:
				playerAPI.SCOPE_MODES.VIS:
					actor.sprite.set_texture(glint_small_texture)
				playerAPI.SCOPE_MODES.RAD:
					actor.sprite.set_texture(glint_large_texture)
		if actor.is_in_any_cohorts([actor3D.COHORTS.AI_UNIT, actor3D.COHORTS.MINE_UNIT]):
			match new_mode:
				playerAPI.SCOPE_MODES.VIS:
					actor.sprite.hide()
				playerAPI.SCOPE_MODES.RAD:
					actor.sprite.show()
	pass

func _on_mine_detonated(id: int) -> void:
	for actor in actors:
		if actor.is_in_cohort(actor3D.COHORTS.MINE_SFX):
			if actor.get_identifier() == id:
				actor.audio.play()
	pass

func _on_body_removed(id: int) -> void:
	var remove_actors: Array[actor3D] = []
	for actor in actors:
		if not actor.is_in_cohort(actor3D.COHORTS.MINE_SFX):
			if actor.get_identifier() == id:
				remove_actors.append(actor)
	for actor in remove_actors:
		actors.erase(actor)
		call_deferred("remove_child", actor)
		actor.queue_free()
	pass

func get_pulsar_beams_as_3D_points(star: pulsarBodyAPI) -> Array[PackedVector3Array]:
	var dir1 = Vector2.UP.rotated(star.beam_rotation)
	var ex1 = dir1 + Vector2(0, -500 * system_scalar).rotated(star.beam_rotation)
	var a1 = dir1 + Vector2(0, (-star.radius * 4.0) * system_scalar).rotated(star.beam_rotation)
	var b1 = ex1 + Vector2(0,star.beam_width * system_scalar).rotated(Vector2.ZERO.angle_to_point(ex1))
	var c1 = ex1 + Vector2(0,-star.beam_width * system_scalar).rotated(Vector2.ZERO.angle_to_point(ex1))
	
	var a1_3d = Vector3(a1.x, 0, a1.y)
	var b1_3d = Vector3(b1.x, 0, b1.y)
	var c1_3d = Vector3(c1.x, 0, c1.y)
	
	var a2_3d = -a1_3d
	var b2_3d = -b1_3d
	var c2_3d = -c1_3d
	
	var v_offset = Vector3(0,star.beam_width,0) * system_scalar
	
	var points1: PackedVector3Array = [
		a1_3d, b1_3d + v_offset, c1_3d - v_offset,
		a1_3d, c1_3d + v_offset, b1_3d - v_offset
	]
	
	var points2: PackedVector3Array = [
		a2_3d, b2_3d + v_offset, c2_3d - v_offset,
		a2_3d, c2_3d + v_offset, b2_3d - v_offset
	]
	
	#these points are already rotated according to the stars current beam_rotation variable at the time of the system being loaded! therefore, to find the real rotation for the MeshInstances, do beam_rotation - initial_beam_rotation :>
	return [points1, points2]

func get_surface_texture_for_circular_body(body: circularBodyAPI) -> NoiseTexture2D:
	var texture = circular_body_texture.duplicate(true)
	var noise = texture.noise
	noise.set_seed(randi())
	texture.color_ramp.colors[0] = body.surface_color.lightened(randfn(0.1, 0.01))
	
	if body.get_type() == starSystemAPI.BODY_TYPES.STAR:
		noise.set_frequency(randfn(0.1, 0.01))
	elif body.get_type() == starSystemAPI.BODY_TYPES.PLANET:
		noise.set_frequency(randfn(0.01, 0.0025))
		
		match body.metadata.get("planet_classification"):
			"Terran":
				match body.metadata.get("planet_type"):
					"Hycean":
						texture.color_ramp.colors[0] = Color.GREEN
						noise.fractal_type = 2 #RIDGED
						noise.fractal_gain = 0.0
						noise.fractal_weighted_strength = 1.0
					"Ocean":
						texture.color_ramp.colors[0] = Color.BLACK
						texture.color_ramp.colors[1] = Color.GREEN
						noise.fractal_gain = 2.0
						noise.fractal_weighted_strength = 1.0
						noise.frequency = 0.05
					"Earth-like":
						texture.color_ramp.colors[0] = Color.BLACK
						texture.color_ramp.colors[1] = Color.SKY_BLUE
						noise.fractal_gain = 0.0
						noise.fractal_weighted_strength = 1.0
					_:
						noise.fractal_type = [FastNoiseLite.FractalType.FRACTAL_FBM, FastNoiseLite.FractalType.FRACTAL_NONE, FastNoiseLite.FractalType.FRACTAL_PING_PONG, FastNoiseLite.FractalType.FRACTAL_RIDGED].pick_random()
						if randf() > 0.75:
							texture.color_ramp.colors[0] = [Color.DARK_GRAY, Color.DIM_GRAY, Color.DARK_SLATE_GRAY, Color.LIGHT_SLATE_GRAY, Color.WEB_GRAY].pick_random()
							texture.color_ramp.colors[0] = texture.color_ramp.colors[0].darkened(randfn(0.25, 0.01))
			"Neptunian":
				texture.width = texture.width / 4
				noise.domain_warp_enabled = true
				noise.domain_warp_fractal_type = 2 #DOMAIN_WARP_FRACTAL_INDEPENDENT
				noise.domain_warp_amplitude = global_data.get_randf(20.0, 45.0)
				texture.seamless_blend_skirt = 0.5
				if randf() >= 0.99:
					texture.width = 1
			"Jovian":
				texture.width = (texture.width / 4) / 2
				noise.domain_warp_enabled = true
				noise.domain_warp_fractal_type = 2 #DOMAIN_WARP_FRACTAL_INDEPENDENT
				noise.domain_warp_amplitude = global_data.get_randf(15.0, 120.0)
				texture.seamless_blend_skirt = 0.5
				if randf() >= 0.975:
					texture.color_ramp.colors[0] = [Color.CHARTREUSE, Color.DARK_MAGENTA, Color.DARK_SLATE_GRAY, Color.MISTY_ROSE, Color.HOT_PINK, Color.MEDIUM_AQUAMARINE].pick_random()
					texture.color_ramp.colors[0] = texture.color_ramp.colors[0].darkened(randfn(0.1, 0.01))
	
	return texture

func _exit_tree() -> void: #thread stuff
	mutex.lock()
	exit_tex_gen_thread = true
	mutex.unlock()
	
	if tex_gen_thread != null:
		if tex_gen_thread.is_started():
			tex_gen_thread.wait_to_finish()
	pass






func _on_toggle_scope_mode_switch_button() -> void: #system_map checks for keybind 'SC_SCOPE_SWITCH' and sends change to game.gd, which sends it here
	mode_switch_button.set_pressed(!mode_switch_button.button_pressed)
	pass

func _on_mode_switch_button_toggled(toggled_on: bool) -> void:
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "scope_mode_switch")
	if not toggled_on:
		mode_switch_button.set_pressed_no_signal(false)
		scope_mode = playerAPI.SCOPE_MODES.VIS
		get_tree().call_group("audioHandler", "play_once", load("uid://bcahs3q6yv8yv"), 0.0, "SFX")
	else:
		mode_switch_button.set_pressed_no_signal(true)
		scope_mode = playerAPI.SCOPE_MODES.RAD
		get_tree().call_group("audioHandler", "play_once", load("uid://do2rl0w7wqiio"), 0.0, "SFX")
	pass

func toggle_mode_switch_button_to_mode(_new_mode: playerAPI.SCOPE_MODES) -> void:
	match _new_mode:
		playerAPI.SCOPE_MODES.VIS:
			_on_mode_switch_button_toggled(false)
		playerAPI.SCOPE_MODES.RAD:
			_on_mode_switch_button_toggled(true)
	pass
