extends "res://Scenes/System Map/custom_tooltip_button.gd"

@export var texture_node: NodePath

const UP_HEIGHT = 25
const DOWN_HEIGHT = 10

func _ready() -> void:
	connect("button_down", _on_button_down)
	connect("button_up", _on_button_up)
	pass

func _on_button_down():
	get_node(texture_node).set_position(Vector2(0,-DOWN_HEIGHT))
	pass

func _on_button_up():
	get_node(texture_node).set_position(Vector2(0,-UP_HEIGHT))
	pass

func _process(_delta: float) -> void:
	if is_disabled():
		get_node(texture_node).set_self_modulate(Color.GRAY)
	else:
		get_node(texture_node).set_self_modulate(Color.WHITE)
	pass
