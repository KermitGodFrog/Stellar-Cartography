extends CenterContainer

@export var target_objective_wID: String
var last_popup_state: int = -1 #below STATES constituting 0, 1, 2

@export var text_box_path: String
@export var text_box_size: Vector2
@export_node_path() var track
@export var track_offset: Vector2

@export var background_path: String
@export_range(0.0, 1.0, 0.001) var background_alpha = 0.416

@export_multiline var info: String

##if applicable
@export var close_button_path: String



#primary
func _ready() -> void:
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
		set_global_position((get_node(track).get_global_position() + (get_node(track).get_size() / 2) - (get_size() / 2)) + track_offset)
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


#misc
func set_popup_state(_state: objectiveAPI.STATES) -> void: # this is whats modified by inherited classes
	pass
