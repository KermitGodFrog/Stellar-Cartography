extends Node2D

signal map_updated

var jumps_remaining: int = 0
var systems_traversed: int = 0
var systems: Array = []
const label_font = preload("uid://xrcqj2080elm")
var draw_landmarks: Dictionary = {"The Core": systems_to_distance(0), "The Frontier": systems_to_distance(5), "The Abyss": systems_to_distance(15), "New Eden": systems_to_distance(25)}

@onready var station_icon = preload("uid://bh57lngfca4xf")

@onready var camera = $camera

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
	station_icon.draw_rect(get_canvas_item(), Rect2((highest_pos.x - station_size * 2) - station_size / 2, station_v_offset - station_size / 2, station_size, station_size), false, Color.GREEN)
	pass

func _on_map_updated():
	queue_redraw()
	pass


func add_new_system(_systems_traversed: int):
	systems_traversed = _systems_traversed
	systems.append(Vector2(global_data.get_randi(-100,100), systems_to_distance(systems_traversed)))
	emit_signal("map_updated")
	pass

func generate_up_to_system(_systems_traversed: int):
	systems_traversed = _systems_traversed
	for system in _systems_traversed:
		systems.append(Vector2(global_data.get_randi(-100,100), systems_to_distance(system)))
	pass


static func systems_to_distance(_systems: int) -> float:
	return -(_systems * 100)


func _on_journey_map_window_close_requested():
	owner.hide()
	pass


func _on_journey_map_window_about_to_popup() -> void:
	camera.position = Vector2(0,systems_to_distance(systems_traversed))
	pass
