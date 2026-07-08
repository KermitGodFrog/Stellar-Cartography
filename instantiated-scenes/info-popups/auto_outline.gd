extends Control

@onready var oscillate = $colorOscillate

@export var target_objective_wID: String
var last_popup_state: int = -1 #below STATES constituting 0, 1, 2

@export_node_path() var track

var current_color: Color = Color.YELLOW

func _ready() -> void:
	oscillate.oscillate_property(self, "current_color", Color.YELLOW, Color.GOLDENROD, 30, 1, true, false)
	pass

func _process(_delta: float) -> void:
	var panel = get("theme_override_styles/panel")
	panel.set("border_color", current_color)
	if track != null:
		set_size(get_node(track).get_size())
		set_global_position(((get_node(track).get_global_position() + (get_node(track).get_size() / 2) - (get_size() / 2))))
	pass

func _on_active_objectives_changed(active_objectives: Array[objectiveAPI]):
	for obj in active_objectives:
		if obj.get_wID() == target_objective_wID:
			var obj_state = obj.get_state()
			if obj_state != last_popup_state:
				set_popup_state(obj_state)
				last_popup_state = obj_state
	pass

func set_popup_state(_state: objectiveAPI.STATES) -> void:
	match _state:
		objectiveAPI.STATES.NONE:
			show()
		_:
			hide()
	pass
