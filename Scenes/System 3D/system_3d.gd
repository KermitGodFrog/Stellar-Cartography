extends Node3D

signal foundBody(id: int)
signal addConsoleEntry(entry_text: String, text_color: Color)

var TUTORIAL_INGRESS_OVERRIDE: bool = false
var TUTORIAL_OMISSION_OVERRIDE: bool = false

var system: starSystemAPI
var player_position: Vector2
var target_position: Vector2
var locked_body_identifier: int
var label_locked_body_identifier: int

var body_3d = preload("res://Instantiated Scenes/Body 3D/body_3d.tscn")
var entity_3d = preload("res://Instantiated Scenes/Body 3D/entity_3d.tscn")

@onready var control = $camera_offset/camera/canvas_layer/control
@onready var camera_offset = $camera_offset
@onready var camera = $camera_offset/camera
@onready var locked_body_label = $camera_offset/camera/canvas_layer/control/locked_body_label
@onready var post_process = $camera_offset/camera/canvas_layer/post_process
@onready var star_omni_light = $star_omni_light

var system_scalar: float = 10.0
var body_detection_range: int = 1000
var target_fov: float = 75

#for wormholes obv
var wormhole_shader = preload("res://Scenes/wormhole_shader.gdshader")

func _ready():
	control.connect("targetFOVChange", _on_target_FOV_change)
	pass

func _physics_process(_delta):
	#setting post process
	
	var fov_to_pixel_size = remap(camera.fov, 10, 75, 8, 2)
	post_process.material.set("shader_parameter/pixel_size", round(fov_to_pixel_size))
	
	#setting player distance, locking player distance from bodie and moving bodies
	camera_offset.position = Vector3((player_position.x * system_scalar), 0, (player_position.y * system_scalar))
	for child in get_children():
		if child.is_in_group("body_3d"):
			var associated_body = system.get_body_from_identifier(child.get_identifier())
			if associated_body:
				child.position = Vector3(associated_body.position.x * system_scalar, 0, associated_body.position.y * system_scalar)
				
				var min_dist = ((associated_body.radius * system_scalar) * 1.1) + 1.0
				if camera_offset.position.distance_to(child.position) < min_dist:
					camera_offset.position = child.position + (child.position.direction_to(camera_offset.position) * min_dist)
	
	#looking at locked body or looking at target position
	if locked_body_identifier:
		var locked_body: Node
		for child in get_children():
			if child.is_in_group("body_3d"):
				if child.get_identifier() == locked_body_identifier:
					locked_body = child
		if locked_body and target_position == Vector2.ZERO:
			camera.global_transform = camera.global_transform.looking_at(locked_body.global_transform.origin)
			camera.global_transform = camera.global_transform.orthonormalized()
		elif target_position:
			camera.global_transform = camera.global_transform.looking_at(Vector3((target_position.x * system_scalar), 0, (target_position.y * system_scalar)))
			camera.global_transform = camera.global_transform.orthonormalized()
	elif target_position:
		camera.global_transform = camera.global_transform.looking_at(Vector3((target_position.x * system_scalar), 0, (target_position.y * system_scalar)))
		camera.global_transform = camera.global_transform.orthonormalized()
	
	camera.fov = lerp(camera.fov, target_fov, 0.05)
	
	#detecting bodies
	for child in get_children():
		if child.is_in_group("body_3d"):
			var a = camera.global_transform.basis.z
			var b = (camera.global_transform.origin - child.global_transform.origin).normalized() 
			if acos(a.dot(b)) <= deg_to_rad(camera.fov):
				var associated_body = system.get_body_from_identifier(child.get_identifier()) #repeat code ?!?!?!?!?!?!?!??!?!?!?!?!??!!
				if associated_body:
					var detection_scalar = camera_offset.position.distance_to(child.position) * camera.fov
					if detection_scalar < body_detection_range and associated_body.is_known() == false:
						
						if associated_body.is_hidden():
							continue
						elif associated_body.get_display_name() == "Ingress":
							if TUTORIAL_INGRESS_OVERRIDE == true:
								continue
						elif associated_body.get_display_name() == "Omission":
							if TUTORIAL_OMISSION_OVERRIDE == true:
								continue
						
						emit_signal("foundBody", child.get_identifier())
						var star_rarity_multiplier = system.get_first_star_discovery_multiplier()
						if not associated_body.metadata.has("value"): emit_signal("addConsoleEntry", str("DISCOVERED: ", associated_body.get_display_name()), Color.DARK_GREEN)
						elif associated_body.metadata.has("value"): emit_signal("addConsoleEntry", str("DISCOVERED: ", associated_body.get_display_name(), " (est. value ", round(associated_body.metadata.get("value") * star_rarity_multiplier), "n) [%.2fx]") % star_rarity_multiplier, Color.DARK_GREEN)
	
	#this is broked because when you unlock a body by moving the camera target pos, the locked_body_identifier variable on this script remains the same - thereofore, it always displays that you are locked to a body
	#setting locked_body_label text
	var body: bodyAPI = system.get_body_from_identifier(label_locked_body_identifier)
	if body:
		if body.is_known():
			locked_body_label.set_text(str("LOCKED: ", body.get_display_name()))
		elif body.is_theorised_not_known():
			locked_body_label.set_text("LOCKED: Unknown")
	elif target_position != Vector2.ZERO:
		locked_body_label.set_text("LOCKED: MANUAL")
	else: 
		locked_body_label.set_text("")
	pass

func spawnBodies():
	for child in get_children():
		if child.is_in_group("body_3d"):
			call_deferred("remove_child", child)
			child.queue_free()
	for body in system.bodies:
		if body is circularBodyAPI:
			var new_body_3d = body_3d.instantiate()
			new_body_3d.set_identifier(body.get_identifier())
			if body.get_type() == starSystemAPI.BODY_TYPES.PLANET:
				new_body_3d.initialize(body.radius * system_scalar, system.get_first_star().surface_color, body.surface_color, 0.25)
			elif body.get_type() == starSystemAPI.BODY_TYPES.STAR:
				new_body_3d.initialize(body.radius * system_scalar, body.surface_color, body.surface_color, 1.0)
				star_omni_light.light_color = body.surface_color
				star_omni_light.light_size = body.radius
			elif body.get_type() == starSystemAPI.BODY_TYPES.WORMHOLE:
				new_body_3d.initialize(body.radius * system_scalar, system.get_first_star().surface_color, body.surface_color, 0.75, wormhole_shader)
			add_child(new_body_3d) 
		elif body is glintBodyAPI:
			spawn_glint_body_3d_for_identifier(body.get_identifier())
		elif body is customBodyAPI:
			if body.mesh_path.is_empty():
				spawn_glint_body_3d_for_identifier(body.get_identifier())
				continue
			#loading mesh
			#putting mesh in scene
			#etc
	pass

func spawn_glint_body_3d_for_identifier(id: int):
	var new_entity_3d = entity_3d.instantiate()
	new_entity_3d.set_identifier(id)
	new_entity_3d.initialize(pow(pow(10, -1.3), 0.28) / 128) #pixel size, can be different for stations/anomalies
	add_child(new_entity_3d)
	pass



func reset_locked_body():
	locked_body_identifier = 0
	label_locked_body_identifier = 0
	pass

func _on_target_FOV_change(fov: float):
	target_fov = fov
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "scopes_fov_change")
	pass
