extends PanelContainer

signal changed()
signal hovered()

@export var wID: String

func _ready() -> void:
	connect("mouse_entered", _on_mouse_entered)
	pass

func reset_display() -> void:
	pass

func update_display() -> void:
	pass

func _on_mouse_entered() -> void:
	emit_signal("hovered", get_wID())
	pass



func get_wID() -> String:
	return wID
