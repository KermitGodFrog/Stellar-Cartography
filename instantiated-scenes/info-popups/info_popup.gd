extends CenterContainer

@export var target_objective_wID: String
var last_popup_state: int = -1 #below STATES constituting 0, 1, 2

@export var text_box_path: String
@export_node_path() var track
@export var track_offset: Vector2

@export_multiline var info: String

func _ready() -> void:
	get_node(NodePath(text_box_path)).set_text(info)
	connect("visibility_changed", _on_visibility_changed)
	pass

func _on_active_objectives_changed(active_objectives: Array[objectiveAPI]):
	for obj in active_objectives:
		if obj.get_wID() == target_objective_wID:
			var obj_state = obj.get_state()
			if obj_state != last_popup_state:
				set_popup_state(obj_state)
				last_popup_state = obj_state
	pass

func _on_visibility_changed() -> void:
	if track != null:
		set_position(get_node(track).position + track_offset)
	pass






func set_popup_state(_state: objectiveAPI.STATES) -> void: # this is whats modified by inherited classes
	pass
