extends Node3D

@onready var space_whale_scene = preload("res://Instantiated Scenes/Space Whales/adult_space_whale.tscn")

@onready var directional_light = $directional_light
@onready var camera = $camera_offset/camera
@onready var camera_offset = $camera_offset

var GENERATION_POSITIONS: PackedVector3Array = []
var GENERATION_BASIS: Basis
const GENERATION_POSITION_ITERATIONS = 30

const CAMERA_ROTATION_MAGNITUDE = 1
var target_fov: float = 75

var system : starSystemAPI
var current_entity : entityAPI = null
var player_position: Vector2 = Vector2.ZERO

func _unhandled_input(event):
	if event.is_action_pressed("left_mouse", true):
		var viewport_size_y = get_viewport().get_visible_rect().size.y
		var viewport_size_x = get_viewport().get_visible_rect().size.x
		var mouse_pos_y = get_viewport().get_mouse_position().y
		var mouse_pos_x = get_viewport().get_mouse_position().x
		
		if mouse_pos_y > (viewport_size_y - viewport_size_y / 10):
			rotate_camera_basis(Vector3.LEFT)
		if mouse_pos_y < (viewport_size_y / 10):
			rotate_camera_basis(Vector3.RIGHT)
		if mouse_pos_x > (viewport_size_x - viewport_size_x / 10):
			rotate_camera_basis(Vector3.DOWN)
		if mouse_pos_x < (viewport_size_x / 10):
			rotate_camera_basis(Vector3.UP)
	pass

func rotate_camera_basis(dir: Vector3) -> void:
	camera.transform.basis = camera.transform.basis.rotated(dir, deg_to_rad(CAMERA_ROTATION_MAGNITUDE))
	pass



func _physics_process(delta):
	camera.fov = lerp(camera.fov, target_fov, 0.05)
	if current_entity:
		var entity_dir_from_player = player_position.direction_to(current_entity.position)
		update_camera_offset_dir(Vector3(entity_dir_from_player.x, 0, entity_dir_from_player.y))
		
		var first_star = system.get_first_star()
		if first_star:
			var star_dir_from_entity = current_entity.position.direction_to(first_star.position)
			update_star_dir(Vector3(-star_dir_from_entity.x, 0, -star_dir_from_entity.y))
	pass








func _on_current_entity_changed(new_entity : entityAPI):
	current_entity = new_entity
	
	if current_entity.stored_generation_positions.is_empty():
		for i in GENERATION_POSITION_ITERATIONS:
			GENERATION_POSITIONS.append(Vector3(global_data.get_randi(-75,75), 0, global_data.get_randi(-75, 75)))
		current_entity.stored_generation_positions = GENERATION_POSITIONS
		print("GENERATING NEW POSITIONS")
	
	if not current_entity.stored_generation_basis:
		current_entity.stored_generation_basis = Basis(game_data.GENERATION_VECTORS.pick_random(), deg_to_rad(global_data.get_randi(0,360)))
		print("GENERATING NEW BASIS")
	
	GENERATION_POSITIONS = current_entity.stored_generation_positions
	GENERATION_BASIS = current_entity.stored_generation_basis
	
	print("SPAWNING")
	
	match current_entity.entity_classification:
		game_data.ENTITY_CLASSIFICATIONS.SPACE_WHALE_POD:
			var ii: int = 0
			
			for whale in 10:
				if (ii + 1) < GENERATION_POSITIONS.size():
					ii += 1
					var pos = GENERATION_POSITIONS[ii]
					
					var space_whale = space_whale_scene.instantiate()
					space_whale.transform = Transform3D(GENERATION_BASIS, pos)
					space_whale.transform.basis = space_whale.transform.basis.rotated(game_data.GENERATION_VECTORS.pick_random(), deg_to_rad(global_data.get_randi(0,20)))
					space_whale.initial_basis = space_whale.transform.basis
					space_whale.target_basis = space_whale.initial_basis
					
					add_child(space_whale)
				
				else: break
	
	#regenerate terrain and stuff!
	pass

func _on_current_entity_cleared():
	current_entity = null
	
	for prop in get_tree().get_nodes_in_group("long_range_scopes_prop"):
		prop.queue_free()
	
	#degererate terrain and stuff and dont allow player to view the scopes n stuff just blank screen n stuff yknow yknow
	pass




func update_star_dir(dir: Vector3) -> void:
	directional_light.transform.basis = directional_light.transform.basis.looking_at(dir)
	pass

func update_camera_offset_dir(dir: Vector3) -> void:
	camera_offset.transform.basis = camera_offset.transform.basis.looking_at(dir)
	pass


func _on_fov_slider_value_changed(value):
	target_fov = value
	pass
