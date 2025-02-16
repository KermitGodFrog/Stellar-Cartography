extends Node2D

signal map_updated

var jumps_remaining: int = 0
var systems_traversed: int = 0
var systems: Array = []
const label_font = preload("res://Graphics/Fonts/RobotoMono Medium.ttf")
var draw_landmarks: Dictionary = {"The Core": -(0 * 100), "The Frontier": -(5 * 100), "The Abyss": -(15 * 100), "New Eden": -(25 * 100)}

@onready var station_frame = preload("res://Graphics/station_frame.png")

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
	
	var station_v_offset = -(systems_traversed + jumps_remaining) * 100.0
	var station_size: int = 32
	
	draw_line(Vector2(highest_pos.x, station_v_offset), Vector2(highest_pos.x - station_size, station_v_offset), Color.GREEN, 3.0)
	station_frame.draw_rect(get_canvas_item(), Rect2((highest_pos.x - station_size * 2) - station_size / 2, station_v_offset - station_size / 2, station_size, station_size), false, Color.GREEN)
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
