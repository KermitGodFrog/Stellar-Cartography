extends PanelContainer

signal changed(_wID: String)
signal hovered(_wID: String)

@export var wID: String

func _ready() -> void:
	connect("mouse_entered", _on_mouse_entered)
	pass



# the big 3

func reset_display_to_applied() -> void: #reset to current applied settings
	pass

func reset_display_to_default() -> void: #reset to default settings
	pass

func update_display() -> void:
	pass



#misc

func _on_mouse_entered() -> void:
	emit_signal("hovered", get_wID())
	pass

func get_wID() -> String:
	return wID
