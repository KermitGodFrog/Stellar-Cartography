extends CenterContainer

@export var target_objective_wID: String
var last_popup_state: int = -1 #below STATES constituting 0, 1, 2

@export_node_path() var mid_panel
@export var text_box_path: String
@export var text_box_size: Vector2
@export_node_path() var track
@export var track_offset: Vector2

@export var background_path: String
@export_range(0.0, 1.0, 0.001) var background_alpha = 0.416

@export_multiline var info: String

##if applicable
@export var close_button_path: String

var manual_offset: Vector2 = Vector2.ZERO 
var dragging: bool = false

#primary
func _ready() -> void:
	if track != null:
		get_node(mid_panel).mouse_filter = Control.MOUSE_FILTER_STOP
		get_node(mid_panel).mouse_default_cursor_shape = Control.CURSOR_MOVE
	get_node(mid_panel).connect("gui_input", _on_mid_panel_gui_input)
	
	get_node(NodePath(text_box_path)).set_text(global_data.replace_keybind_references(info))
	if text_box_size != Vector2.ZERO:
		get_node(NodePath(text_box_path)).set_custom_minimum_size(text_box_size)
	if close_button_path.length() > 0:
		get_node(NodePath(close_button_path)).connect("pressed", _on_close_button_pressed)
	if background_path.length() > 0:
		get_node(NodePath(background_path)).set_color(Color("2e2e2e", background_alpha))
	pass

func _process(_delta: float) -> void:
	if track != null:
		set_global_position(((get_node(track).get_global_position() + (get_node(track).get_size() / 2) - (get_size() / 2)) + track_offset) + manual_offset)
	pass



#signals
func _on_active_objectives_changed(active_objectives: Array[objectiveAPI]):
	for obj in active_objectives:
		if obj.get_wID() == target_objective_wID:
			var obj_state = obj.get_state()
			if obj_state != last_popup_state:
				set_popup_state(obj_state)
				last_popup_state = obj_state
	pass

func _on_close_button_pressed() -> void:
	hide()
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "info_popup_close_press", target_objective_wID)
	pass

func _on_mid_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			dragging = true
		else:
			dragging = false
	elif event is InputEventMouseMotion:
		if dragging:
			manual_offset += event.relative
	pass

#misc
func set_popup_state(_state: objectiveAPI.STATES) -> void: # this is whats modified by inherited classes
	pass
