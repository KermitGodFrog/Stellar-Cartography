extends Node3D

signal addConsoleItem(text: String, bg_color: Color, time: int)
signal addPlayerValue(amount: int)

@onready var space_whale_scene = preload("res://Instantiated Scenes/Space Whales/adult_space_whale.tscn")
@onready var hud_default = preload("res://Graphics/long_range_scopes_hud4.png")
@onready var hud_holding = preload("res://Graphics/long_range_scopes_hud3.png")
@onready var hud_release = preload("res://Graphics/long_range_scopes_hud2.png")

@onready var directional_light = $directional_light
@onready var camera = $camera_offset/camera
@onready var camera_offset = $camera_offset
@onready var no_current_entity_bg = $camera_offset/camera/canvas_layer/no_current_entity_bg
@onready var photo_texture = $camera_offset/camera/canvas_layer/photo_texture
@onready var captures_remaining_label = $camera_offset/camera/canvas_layer/captures_remaining_label
@onready var hud = $camera_offset/camera/canvas_layer/hud
@onready var fov_container = $camera_offset/camera/canvas_layer/fov_container

var GENERATION_POSITIONS: PackedVector3Array = []
var GENERATION_BASIS: Basis
const GENERATION_POSITION_ITERATIONS = 30

const CAMERA_ROTATION_MAGNITUDE = 1
var target_fov: float = 75

var system : starSystemAPI
var current_entity : entityAPI = null
var player_position: Vector2 = Vector2.ZERO

var camera_offset_target_basis: Basis

@export var prop_size_reward_curve: Curve
@export var prop_distance_reward_curve: Curve

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			
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
	
	if event.is_action_pressed("gkooble"):
		hud.set_texture(hud_holding)
	
	if event.is_action_released("gkooble"):
		
		if current_entity: if current_entity.captures_remaining > 0:
			current_entity.remove_captures_remaining(1)
			captures_remaining_label.text = str(current_entity.captures_remaining)
			
			var photo_total_value: int = 0
			var photo_total_size_reward: int = 0
			var photo_total_distance_reward: int = 0
			var photo_total_posing_reward: int = 0
			var photo_total_characteristics_reward: int = 0
			
			for prop in get_tree().get_nodes_in_group("long_range_scopes_prop"):
				if get_viewport().get_camera_3d().is_position_in_frustum(prop.transform.origin):
					var prop_positions: PackedVector3Array = prop.get_positions() # MUST BE 4 POINTS!!!!
					var fixed_positions: PackedVector2Array = []
					for pos in prop_positions:
						fixed_positions.append(get_viewport().get_camera_3d().unproject_position(pos))
					
					var projected_positions: Array = []
					for pos in fixed_positions:
						projected_positions.append(pos.project(Vector2.UP).y)
					projected_positions.sort()
					var vertical_size = (projected_positions.back() - projected_positions.front())
					
					var screen_centre = get_viewport().get_visible_rect().size / 2
					var distances_from_centre: Array = []
					for pos in fixed_positions:
						distances_from_centre.append(pos.distance_to(screen_centre))
					var avg_distance_from_centre = global_data.average(distances_from_centre)
					
					var is_posing: bool = prop.is_posing()
					
					var vertical_size_remapped = remap(vertical_size, 0, 800, 0, 1)
					var distance_remapped = remap(avg_distance_from_centre, 0, 400, 0, 1)
					var vertical_size_reward: int = 0
					var distance_reward: int = 0
					var posing_reward: int = 0
					var characteristics_reward: int = prop.get_characteristics()
					
					if vertical_size <= 800: vertical_size_reward = int(prop_size_reward_curve.sample(vertical_size_remapped))
					if avg_distance_from_centre <= 400: distance_reward = int(prop_distance_reward_curve.sample(distance_remapped) * vertical_size_remapped)
					if is_posing: posing_reward = distance_reward + vertical_size_reward
					
					photo_total_value += vertical_size_reward + distance_reward + posing_reward + characteristics_reward
					photo_total_size_reward += vertical_size_reward
					photo_total_distance_reward += distance_reward
					photo_total_posing_reward += posing_reward
					photo_total_characteristics_reward += characteristics_reward
			
			emit_signal("addConsoleItem", str("Size of subject(s): ", photo_total_size_reward), Color("353535"), 1500)
			emit_signal("addConsoleItem", str("Framing of subject(s): ", photo_total_distance_reward), Color("353535"), 1500)
			emit_signal("addConsoleItem", str("Posing of subject(s): ", photo_total_posing_reward), Color("353535"), 1500)
			emit_signal("addConsoleItem", str("Characteristics of subject(s): ", photo_total_characteristics_reward), Color("353535"), 1500)
			emit_signal("addConsoleItem", str("Total photo value: ", photo_total_value), Color.GOLD, 2000)
			
			emit_signal("addPlayerValue", photo_total_value)
			
			
			
			hud.hide()
			captures_remaining_label.hide()
			fov_container.hide()
			
			await RenderingServer.frame_post_draw
			var image: Image = camera.get_viewport().get_texture().get_image()
			
			var image_path = "Debug/test.png"
			image.save_png(image_path)
			
			var image_texture: ImageTexture = ImageTexture.new()
			image_texture.create_from_image(image)
			await RenderingServer.frame_post_draw
			photo_texture.texture = image_texture
			
			#DOESNT WORK !!!!!! :((((((( WHHYYHYHYYHYHHYHYHYHYHYHYY
			hud.show()
			captures_remaining_label.show()
			fov_container.show()
			
			#photo_texture.texture = image
			#dont work ^^^
		
		hud.set_texture(hud_release)
		var reset_timer = get_tree().create_timer(0.25)
		reset_timer.connect("timeout", _on_reset_hud_image)
	pass

func rotate_camera_basis(dir: Vector3) -> void:
	camera.transform.basis = camera.transform.basis.rotated(dir, deg_to_rad(CAMERA_ROTATION_MAGNITUDE))
	pass



func _physics_process(delta):
	camera.fov = lerp(camera.fov, target_fov, 0.05)
	camera_offset.transform.basis = camera_offset.transform.basis.slerp(camera_offset_target_basis, 0.5)
	if current_entity:
		var entity_dir_from_player = player_position.direction_to(current_entity.position)
		update_camera_offset_dir(Vector3(entity_dir_from_player.x, 0, entity_dir_from_player.y))
		
		var first_star = system.get_first_star()
		if first_star:
			var star_dir_from_entity = current_entity.position.direction_to(first_star.position)
			update_star_dir(Vector3(-star_dir_from_entity.x, 0, -star_dir_from_entity.y))
	pass

func _on_current_entity_changed(new_entity : entityAPI):
	if current_entity != new_entity: # to prevent infinite generation by just re-pressing the go-to button, maybe move to game.gd?
		no_current_entity_bg.hide()
		current_entity = new_entity
		captures_remaining_label.text = str(current_entity.captures_remaining)
		
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
	no_current_entity_bg.show()
	current_entity = null
	captures_remaining_label.text = str("")
	
	for prop in get_tree().get_nodes_in_group("long_range_scopes_prop"):
		prop.queue_free()
	
	#degererate terrain and stuff and dont allow player to view the scopes n stuff just blank screen n stuff yknow yknow
	pass

func _on_reset_hud_image() -> void:
	hud.set_texture(hud_default)
	pass


func update_star_dir(dir: Vector3) -> void:
	directional_light.transform.basis = directional_light.transform.basis.looking_at(dir)
	pass

func update_camera_offset_dir(dir: Vector3) -> void:
	camera_offset_target_basis = camera_offset.transform.basis.looking_at(dir)
	pass


func _on_fov_slider_value_changed(value):
	target_fov = value
	pass


func _on_long_range_scopes_window_close_requested():
	owner.hide()
	pass
