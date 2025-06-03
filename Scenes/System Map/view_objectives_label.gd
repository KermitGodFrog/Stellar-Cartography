extends Label

@onready var curve = preload("res://Scenes/System Map/view_objectives_label_fade_out.tres") #consider this to be necessary as it has quite a weird curve that i am uncertain i can replicate in code

var time: float = 0.0

const starting_color: Color = Color.WHITE
const max_time: float = 50

func _physics_process(delta: float) -> void:
	time += delta
	set("theme_override_colors/font_color", Color(starting_color, remap(time, 0.0, max_time, 1.0, 0.0)))
	
	#this should NOT be in _physics_process oml
	if time < max_time:
		show()
		var r = convert_events_to_readable(InputMap.action_get_events("SC_PAUSE"))
		if r.length() == 0:
			r = "UNSET"
		set_text("Press %s to view objectives" % r)
	elif time > max_time:
		hide()
	pass



func convert_events_to_readable(input_array: Array[InputEvent]) -> String: #this is NEARLY the function in keybind_option.gd (besides the brackets and spacing) - might want to have both functions in game_data or smth later. kinda a temp fix
	var s: String = ""
	for event in input_array:
		if event is InputEventKey:
			if event.physical_keycode:
				var keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
				s += "[%s]" % OS.get_keycode_string(keycode)
			else:
				s +="[%s]" % OS.get_keycode_string(event.keycode)
		if event is InputEventJoypadButton:
			s += "[JOY_%s]" % event.button_index
		if event is InputEventMouseButton:
			s += "[MOUSE_%s]" % event.button_index
	return s
