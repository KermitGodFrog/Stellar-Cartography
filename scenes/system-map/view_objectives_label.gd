extends Label

@onready var curve = preload("uid://lk2jrbgdrxym") #consider this to be necessary as it has quite a weird curve that i am uncertain i can replicate in code

var countdown_overlay_shown: bool = false

var time: float = 0.0

const starting_color: Color = Color.WHITE
const max_time: float = 25.0

var previous_hash: String = String()

func _on_active_objectives_changed(active_objectives: Array[objectiveAPI]):
	var new_hash: String = String()
	for o in active_objectives:
		new_hash += str(hash(o.get_wID()))
		new_hash += str(hash(o.get_state()))
	
	if new_hash != previous_hash:
		time = float()
	
	previous_hash = new_hash
	pass

func _physics_process(delta: float) -> void:
	time += delta
	set("theme_override_colors/font_color", Color(starting_color, remap(time, 0.0, max_time, 1.0, 0.0)))
	
	#this should NOT be in _physics_process oml
	if time < max_time:
		show()
		var r = global_data.convert_events_to_readable(InputMap.action_get_events("SC_PAUSE"))
		if r.length() == 0:
			r = "[UNSET]"
		set_text("Press %s to view objectives" % r)
	elif time > max_time:
		hide()
	
	if countdown_overlay_shown:
		hide()
	pass







func _on_update_countdown_overlay_shown(shown: bool):
	countdown_overlay_shown = shown
	pass
