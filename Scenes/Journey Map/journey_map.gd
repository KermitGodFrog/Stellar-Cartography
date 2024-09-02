extends Node2D

signal map_updated

var systems_traversed: int = 0
var systems: Array = []
var label_font = preload("res://Graphics/Fonts/RobotoMono Medium.ttf")
var draw_landmarks: Dictionary = {"The Core": 50, "The Frontier": -1500, "The Abyss": -2625, "New Eden": -3450}


func _ready():
	connect("map_updated", _on_map_updated)
	pass

func _draw():
	for system in systems:
		var system_array_pos = systems.rfind(system)
		if (system_array_pos != 0):
			draw_dashed_line(system, systems[system_array_pos - 1], Color.GRAY, 7.0, 7.0, true)
	
	for system in systems:
		draw_circle(system, 10, Color.WHITE)
	
	
	
	var lowest_pos = get_viewport_transform().x - get_viewport_transform().origin
	var highest_pos = get_viewport_transform().x + get_viewport_transform().origin
	
	for landmark in draw_landmarks:
		draw_line(Vector2(lowest_pos.x, draw_landmarks.get(landmark)), Vector2(highest_pos.x, draw_landmarks.get(landmark)), Color.DARK_SLATE_GRAY, 10)
		draw_string(label_font, Vector2(lowest_pos.x,draw_landmarks.get(landmark)), landmark, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	
	
	
	
	
	
	#draw_string(label_font, Vector2(lowest_pos.x,50), "The Core", HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	#draw_string(label_font, Vector2(lowest_pos.x,-1500), "The Frontier", HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	#draw_string(label_font, Vector2(lowest_pos.x,-2625), "The Abyss", HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	#draw_string(label_font, Vector2(lowest_pos.x,-3325), "New Eden", HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	
	
	
	
	pass

func _on_map_updated():
	queue_redraw()
	pass




func add_new_system(_systems_traversed: int):
	systems_traversed = _systems_traversed
	systems.append(Vector2(global_data.get_randi(-100,100), -(systems_traversed * 100)))
	emit_signal("map_updated")
	pass

func generate_up_to_system(_systems_traversed: int):
	systems_traversed = _systems_traversed
	for system in _systems_traversed:
		systems.append(Vector2(global_data.get_randi(-100,100), -(system * 100)))
	pass






func _on_journey_map_window_close_requested():
	owner.hide()
	pass
