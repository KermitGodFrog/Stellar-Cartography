extends "res://instantiated-scenes/info-popups/info_popup.gd"

@onready var video = $mid_panel_fluid/mid_panel/margin/vid
@onready var switch_button = $mid_panel_fluid/switch_button

@export var video_file: String

func _ready() -> void:
	if text_box_size != Vector2.ZERO:
		video.set_custom_minimum_size(text_box_size)
	switch_button.connect("pressed", _on_switch_button_pressed)
	
	var stream = VideoStreamTheora.new()
	stream.set_file(video_file)
	video.set_stream(stream)
	super()
	pass

func _on_switch_button_pressed() -> void:
	get_node(NodePath(text_box_path)).visible = !get_node(NodePath(text_box_path)).visible
	video.visible = !video.visible
	if video.visible:
		video.play()
	else:
		video.stop()
	pass

func set_popup_state(_state: objectiveAPI.STATES) -> void:
	match _state:
		objectiveAPI.STATES.NONE:
			show()
		_:
			hide()
	pass
