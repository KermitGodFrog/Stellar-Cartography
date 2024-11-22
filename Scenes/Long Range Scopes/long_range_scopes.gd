extends Node3D

signal addConsoleItem(text: String, bg_color: Color, time: int)
signal addPlayerValue(amount: int)

enum STATES {DEFAULT, DISPLAY_PHOTO, DISPLAY_RANGEFINDER}
var current_state: STATES = STATES.DEFAULT:
	set(value):
		current_state = value
		_on_state_changed(value)

var STATE_CHANGE_LOCK: bool = false
var state_change_lock_duration: float = 0.1

var _DRAW_MATRICIES: Array[Array] = [[]] #carried to _on_state_changed
var _REWARD_MATRIX: Array = [] #carried to _on_state_changed

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
@onready var value_label = $camera_offset/camera/canvas_layer/value_label
@onready var rangefinder = $camera_offset/camera/canvas_layer/rangefinder

var GENERATION_POSITIONS: PackedVector3Array = []
var GENERATION_BASIS: Basis
const GENERATION_POSITION_ITERATIONS = 30
const CAMERA_ROTATION_MAGNITUDE = 2

var target_fov: float = 75
var state_on_photo_held: STATES = STATES.DEFAULT

var system : starSystemAPI
var current_entity : entityAPI = null
var player_position: Vector2 = Vector2.ZERO

func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if current_state == STATES.DISPLAY_PHOTO or current_state == STATES.DISPLAY_RANGEFINDER:
				set_state(STATES.DEFAULT)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and current_state == STATES.DEFAULT:
			var viewport_size_y = get_viewport().get_visible_rect().size.y
			var viewport_size_x = get_viewport().get_visible_rect().size.x
			var mouse_pos_y = get_viewport().get_mouse_position().y
			var mouse_pos_x = get_viewport().get_mouse_position().x
			
			if mouse_pos_y > (viewport_size_y - viewport_size_y / 10):
				rotate_camera_basis(Vector3.LEFT, CAMERA_ROTATION_MAGNITUDE)
			if mouse_pos_y < (viewport_size_y / 10):
				rotate_camera_basis(Vector3.RIGHT, CAMERA_ROTATION_MAGNITUDE)
			if mouse_pos_x > (viewport_size_x - viewport_size_x / 10):
				rotate_camera_basis(Vector3.DOWN, CAMERA_ROTATION_MAGNITUDE)
			if mouse_pos_x < (viewport_size_x / 10):
				rotate_camera_basis(Vector3.UP, CAMERA_ROTATION_MAGNITUDE)
	
	if event.is_action_pressed("gzooble") and current_state == STATES.DEFAULT:
		var DRAW_MATRICIES: Array[Array] = [[]]
		for prop in get_tree().get_nodes_in_group("long_range_scopes_prop"):
			if get_viewport().get_camera_3d().is_position_in_frustum(prop.transform.origin):
				var prop_positions: PackedVector3Array = prop.get_positions() # MUST BE 4 POINTS!!!!
				var fixed_positions: PackedVector2Array = get_fixed_positions(prop_positions)
				var projected_positions: Array = get_projected_positions(fixed_positions)
				var vertical_size: int = get_vertical_size_from_points(projected_positions)
				
				var x_axis_fixed_positions: Array = []
				var y_axis_fixed_positions: Array = []
				
				for pos in fixed_positions:
					x_axis_fixed_positions.append(pos.x)
					y_axis_fixed_positions.append(pos.y)
				
				var average_position = Vector2(global_data.average(x_axis_fixed_positions), global_data.average(y_axis_fixed_positions))
				
				DRAW_MATRICIES.append([average_position, vertical_size])
		
		_DRAW_MATRICIES = DRAW_MATRICIES
		set_state(STATES.DISPLAY_RANGEFINDER)
	
	if event.is_action_pressed("gkooble"):
		hud.set_texture(hud_holding)
		state_on_photo_held = current_state
	
	if event.is_action_released("gkooble") and current_state == STATES.DEFAULT and state_on_photo_held == STATES.DEFAULT:
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
					var fixed_positions: PackedVector2Array = get_fixed_positions(prop_positions)
					var projected_positions: Array = get_projected_positions(fixed_positions)
					var vertical_size: int = get_vertical_size_from_points(projected_positions)
					var avg_distance_from_centre: int = get_average_to_screen_centre_from_points(fixed_positions)
					
					var is_posing: bool = prop.is_posing()
					
					var vertical_size_remapped = remap(vertical_size, 0, 800, 0, 1)
					var distance_remapped = remap(avg_distance_from_centre, 0, 400, 0, 1)
					var vertical_size_reward: int = 0
					var distance_reward: int = 0
					var posing_reward: int = 0
					var characteristics_reward: int = prop.get_characteristics()
					
					if vertical_size <= 800: vertical_size_reward = int(prop.size_reward_curve.sample(vertical_size_remapped))
					if avg_distance_from_centre <= 400: distance_reward = int(prop.distance_reward_curve.sample(distance_remapped) * vertical_size_remapped)
					if is_posing: posing_reward = distance_reward + vertical_size_reward
					
					photo_total_value += vertical_size_reward + distance_reward + posing_reward + characteristics_reward
					photo_total_size_reward += vertical_size_reward
					photo_total_distance_reward += distance_reward
					photo_total_posing_reward += posing_reward
					photo_total_characteristics_reward += characteristics_reward
			
			emit_signal("addPlayerValue", photo_total_value)
			_REWARD_MATRIX = [photo_total_size_reward, photo_total_distance_reward, photo_total_posing_reward, photo_total_characteristics_reward, photo_total_value]
			set_state(STATES.DISPLAY_PHOTO)
	pass

func rotate_camera_basis(dir: Vector3, camera_rotation_magnitude: int) -> void:
	camera.transform.basis = camera.transform.basis.rotated(dir, deg_to_rad(camera_rotation_magnitude))
	pass

func _physics_process(_delta):
	camera.fov = lerp(camera.fov, target_fov, 0.05)
	if current_entity:
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
	
	#var entity_dir_from_player = player_position.direction_to(current_entity.position)
	#camera_offset.transform.basis = camera_offset.transform.basis.looking_at(Vector3(entity_dir_from_player.x, 0, entity_dir_from_player.y))
	#updates camera rotation when pressing go-to, so removing this fixes bug but not very accurate (especially with light)
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


func get_fixed_positions(prop_positions: PackedVector3Array) -> PackedVector2Array: #unprojects prop positions in 3d to screen space
	var fixed_positions: PackedVector2Array = []
	for pos in prop_positions:
		fixed_positions.append(get_viewport().get_camera_3d().unproject_position(pos))
	return fixed_positions

func get_projected_positions(fixed_positions: PackedVector2Array) -> Array: #projects an array of positions in screen space upwards onto a line (NOT SORTED)
	var projected_positions: Array = []
	for pos in fixed_positions:
		projected_positions.append(pos.project(Vector2.UP).y)
	return projected_positions

func get_vertical_size_from_points(projected_positions: Array) -> int:
	if not projected_positions.is_empty():
		projected_positions.sort()
		var vertical_size = (projected_positions.back() - projected_positions.front())
		return vertical_size
	else: return -1

func get_average_to_screen_centre_from_points(fixed_positions: PackedVector2Array) -> int:
	var screen_centre = get_viewport().get_visible_rect().size / 2
	var distances_from_centre: Array = []
	for pos in fixed_positions:
		distances_from_centre.append(pos.distance_to(screen_centre))
	if not distances_from_centre.is_empty():
		var avg_distance_from_centre = global_data.average(distances_from_centre)
		return avg_distance_from_centre
	else: return -1


func hide_all_hud_elements() -> void:
	hud.hide()
	captures_remaining_label.hide()
	fov_container.hide()
	value_label.hide()
	pass

func show_all_hud_elements() -> void:
	hud.show()
	captures_remaining_label.show()
	fov_container.show()
	value_label.hide()
	pass

func set_state(new_state: STATES):
	if STATE_CHANGE_LOCK == false:
		current_state = new_state
	pass

func _on_state_changed(new_state: STATES):
	STATE_CHANGE_LOCK = true
	get_tree().create_timer(state_change_lock_duration).timeout.connect(_on_state_change_lock_timeout)
	
	
	match new_state:
		STATES.DEFAULT:
			photo_texture.texture = null
			show_all_hud_elements()
			
			hud.set_texture(hud_release)
			var reset_timer = get_tree().create_timer(0.5)
			reset_timer.connect("timeout", _on_reset_hud_image)
			
		STATES.DISPLAY_PHOTO:
			hide_all_hud_elements()
			
			await RenderingServer.frame_post_draw
			var image: Image = camera.get_viewport().get_texture().get_image()
			image.save_png("Debug/test.png")
			var image_texture: ImageTexture = ImageTexture.create_from_image(image)
			photo_texture.texture = image_texture
			
			get_tree().create_timer(1.0).timeout.connect(_on_state_display_photo_advance)
			
		STATES.DISPLAY_RANGEFINDER:
			rangefinder.draw_rangefinder(_DRAW_MATRICIES)
			await RenderingServer.frame_post_draw
			
			hide_all_hud_elements()
			
			await RenderingServer.frame_post_draw
			var image: Image = camera.get_viewport().get_texture().get_image()
			image.save_png("Debug/test.png")
			var image_texture: ImageTexture = ImageTexture.create_from_image(image)
			photo_texture.texture = image_texture
			
			rangefinder.DRAW_MATRICIES.clear()
			rangefinder.queue_redraw()
			
	pass

func _on_state_display_photo_advance() -> void:
	if current_state == STATES.DISPLAY_PHOTO:
		value_label.set_text("Size of subject(s): %s\nFraming of subject(s): %s\nPosing of subject(s): %s\nCharacteristics of subject(s): %s\nTotal photo value: %s\n\nPRESS ANY >>>" % _REWARD_MATRIX)
		value_label.show()
	pass

func _on_state_change_lock_timeout() -> void:
	STATE_CHANGE_LOCK = false
	pass



func _on_fov_slider_value_changed(value):
	target_fov = value
	pass

func _on_long_range_scopes_window_close_requested():
	owner.hide()
	pass
