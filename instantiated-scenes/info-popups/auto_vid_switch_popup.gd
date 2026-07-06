extends "res://instantiated-scenes/info-popups/info_popup.gd"

@onready var video = $mid_panel_fluid/mid_panel/margin/vid_container/vid
@onready var video_container = $mid_panel_fluid/mid_panel/margin/vid_container
@onready var switch_button = $mid_panel_fluid/switch_button
@onready var switch_button_flash = $switch_button_flash
@onready var vid_title = $mid_panel_fluid/mid_panel/margin/vid_title

@export var video_file: String
@export_multiline var video_title_text: String
@export_range(0.001, 10.0, 0.001) var video_aspect_ratio: float = 1.0
@export var start_on_video: bool = false
@export var flash_switch_button_until_pressed: bool = false

var current_color: Color = Color.WHITE

func _ready() -> void:
	vid_title.set_text(video_title_text)
	reset_vid_container_and_title_sizes()
	
	switch_button.connect("pressed", _on_switch_button_pressed)
	
	video_container.set_ratio(video_aspect_ratio)
	
	var stream = VideoStreamTheora.new()
	stream.set_file(video_file)
	video.set_stream(stream)
	
	super()
	
	await get_tree().create_timer(1.0, true).timeout
	
	if start_on_video:
		_on_switch_button_pressed()
	
	if flash_switch_button_until_pressed:
		switch_button_flash.oscillate_property(self, "current_color", Color.WHITE, Color.YELLOW, 20, 10, true)
	pass

func _process(delta: float) -> void:
	switch_button.set("theme_override_colors/font_color", current_color)
	switch_button.set("theme_override_colors/icon_normal_color", current_color)
	
	super(delta) #forgot this and spent AGES debugging it
	pass

func _on_switch_button_pressed() -> void:
	switch_button_flash.clear_active()
	
	reset_vid_container_and_title_sizes()
	
	get_node(NodePath(text_box_path)).visible = !get_node(NodePath(text_box_path)).visible
	video_container.visible = !video_container.visible
	vid_title.visible = !vid_title.visible
	
	if video_container.visible:
		video.play()
		switch_button.set_text("VIEW TEXT")
	else:
		video.stop()
		switch_button.set_text("VIEW VIDEO")
	pass

func set_popup_state(_state: objectiveAPI.STATES) -> void:
	match _state:
		objectiveAPI.STATES.NONE:
			_on_switch_button_pressed()
			_on_switch_button_pressed()
			show()
		_:
			hide()
	pass

func reset_vid_container_and_title_sizes() -> void:
	video_container.set_custom_minimum_size(get_node(NodePath(text_box_path)).get_size())
	video_container.set_size(get_node(NodePath(text_box_path)).get_size())
	vid_title.set_custom_minimum_size(Vector2(get_node(NodePath(text_box_path)).get_size().x, 0))
	vid_title.set_size(get_node(NodePath(text_box_path)).get_size())
	pass
