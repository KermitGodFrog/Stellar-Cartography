extends Control

@onready var scroll = $scroll_container/scroll



func initialize():
	for child in scroll.get_children():
		child.queue_free()
	
	var actions: Array[StringName] = InputMap.get_actions()
	for action in actions:
		if action.begins_with("SC_"):
			var events = InputMap.action_get_events(action)
			var info: String = ""
			for event in events:
				info += event.to_string()
			
			var button = Button.new()
			button.text = action
			button.clip_text = true
			scroll.add_child(button)
	pass


func _on_back_button_pressed():
	visible = !visible
	pass
