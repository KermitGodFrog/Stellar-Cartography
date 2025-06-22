extends TextureButton
enum LISTS {HIERACHY, CHOICES}
enum ACTIONS {SWITCH_COLUMN, VIEW_IN_ENCYCLOPEDIA}

signal activated(_tag: String, _list: LISTS, _action: ACTIONS)

var current_list: LISTS

var tag: String = String()
var data: Dictionary = Dictionary()

func initialize(_tag: String, _data: Dictionary, _list: LISTS) -> void:
	tag = _tag
	data = _data
	current_list = _list
	pass

func _ready() -> void:
	tooltip_title = tag.to_upper()
	texture_normal.gradient.set_color(0, data.get("bg_color", Color.WHITE))
	texture_normal.gradient.set_color(1, data.get("fog_albedo", Color.WHITE))
	pass



#yoinking this from system_map
@onready var custom_tooltip = preload("res://Scenes/Custom Tooltip/custom_tooltip.tscn")
var tooltip_title: String
func _make_custom_tooltip(for_text):
	var custom_tooltip_instance = custom_tooltip.instantiate()
	custom_tooltip_instance.initialize(tooltip_title, for_text)
	return custom_tooltip_instance



func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("activated", tag, current_list, ACTIONS.SWITCH_COLUMN)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			emit_signal("activated", tag, current_list, ACTIONS.VIEW_IN_ENCYCLOPEDIA)
	pass
