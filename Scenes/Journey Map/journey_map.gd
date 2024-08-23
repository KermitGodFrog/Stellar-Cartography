extends Node2D

signal map_updated

var systems_traversed: int = 0
var systems: Array = []

var label_font = preload("res://Graphics/Fonts/RobotoMono Medium.ttf")

func _ready():
	connect("map_updated", _on_map_updated)
	pass





func _draw():
	for system in systems:
		var system_array_pos = systems.rfind(system)
		
		if (system_array_pos != 0):
			draw_dashed_line(system, systems[system_array_pos - 1], Color.GRAY, 7.0, 7.0, true)
		
		draw_circle(system, 10, Color.WHITE)
	
	var lowest_pos = get_viewport_transform().x - get_viewport_transform().origin
	
	
	draw_string(label_font, Vector2(lowest_pos.x,100), "The Core", HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	draw_string(label_font, Vector2(lowest_pos.x,-1500), "The Frontier", HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	draw_string(label_font, Vector2(lowest_pos.x,-2625), "The Abyss", HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
	
	
	pass

func _on_map_updated():
	queue_redraw()
	pass




func add_new_system(_systems_traversed: int):
	systems_traversed = _systems_traversed
	systems.append(Vector2(global_data.get_randi(-100,100), -(systems_traversed * 100)))
	emit_signal("map_updated")
	pass
