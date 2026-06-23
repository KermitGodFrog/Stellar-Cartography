extends "res://instantiated-scenes/info-popups/info_popup.gd"

@export var video_path: String
@export var video_stream: VideoStream
@export var switch_button_path: String

func _ready() -> void:
	if text_box_size != Vector2.ZERO:
		get_node(NodePath(video_path)).set_custom_minimum_size(text_box_size)
	if switch_button_path.length() > 0:
		get_node(NodePath(switch_button_path)).connect("pressed", _on_switch_button_pressed)
	super()
	pass

func _on_switch_button_pressed() -> void:
	get_node(NodePath(text_box_path)).visible = !get_node(NodePath(text_box_path)).visible
	get_node(NodePath(video_path)).visible = !get_node(NodePath(video_path)).visible
	pass

func set_popup_state(_state: objectiveAPI.STATES) -> void:
	match _state:
		objectiveAPI.STATES.NONE:
			show()
		_:
			hide()
	pass
