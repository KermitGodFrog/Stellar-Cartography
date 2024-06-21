extends Control

@onready var item_list = $item_list
@onready var line_edit = $line_edit

signal systemMapPopup
signal system3DPopup
signal sonarPopup
signal barycenterPopup

func add_console_item(text: String, bg_color: Color = Color.WHITE):
	var new_item = item_list.add_item(text, null, false)
	if bg_color != Color.WHITE:
		item_list.set_item_custom_bg_color(new_item, bg_color)
	pass

func _on_line_edit_text_submitted(new_text):
	if new_text:
		var return_msg: String
		if has_method(str("cmd_", new_text)):
			return_msg = call(str("cmd_", new_text))
		else: return_msg = str("command not found: ", new_text)
		
		if return_msg:
			add_console_item(return_msg)
		
		line_edit.clear()
	pass

func cmd_help():
	return str("List of possible commands: ", "system_map, ", "scopes, ", "sonar ")

func cmd_system_map():
	emit_signal("systemMapPopup")
	return str("Opening system map.")

func cmd_scopes():
	emit_signal("system3DPopup")
	return str("Opening scopes.")

func cmd_sonar():
	emit_signal("sonarPopup")
	return str("Opening sonar.")

func cmd_barycenter():
	emit_signal("barycenterPopup")
	return str("Opening barycenter visualizer.")
