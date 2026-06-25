extends "res://instantiated-scenes/info-popups/info_popup.gd"

@onready var video = $mid_panel_fluid/mid_panel/margin/vid_container/vid
@onready var video_container = $mid_panel_fluid/mid_panel/margin/vid_container
@onready var switch_button = $mid_panel_fluid/switch_button
@onready var switch_button_flash = $switch_button_flash

@export var video_file: String
@export_range(0.001, 10.0, 0.001) var video_aspect_ratio: float = 1.0
@export var flash_switch_button_until_pressed: bool = false

func _ready() -> void:
	switch_button.connect("pressed", _on_switch_button_pressed)
	
	video_container.set_ratio(video_aspect_ratio)
	
	var stream = VideoStreamTheora.new()
	stream.set_file(video_file)
	video.set_stream(stream)
	
	if flash_switch_button_until_pressed:
		switch_button_flash.oscillate_property(switch_button, "theme_override_colors/icon_normal_color", Color.WHITE, Color.YELLOW, 20, 10, true)
	
	super()
	pass

func _on_switch_button_pressed() -> void:
	switch_button_flash.clear_active()
	
	get_node(NodePath(text_box_path)).visible = !get_node(NodePath(text_box_path)).visible
	video_container.visible = !video_container.visible
	if video_container.visible:
		video.play()
	else:
		video.stop()
	
	video_container.set_custom_minimum_size(get_node(NodePath(text_box_path)).get_size())
	video_container.set_size(get_node(NodePath(text_box_path)).get_size())
	pass

func set_popup_state(_state: objectiveAPI.STATES) -> void:
	match _state:
		objectiveAPI.STATES.NONE:
			show()
		_:
			hide()
	pass
