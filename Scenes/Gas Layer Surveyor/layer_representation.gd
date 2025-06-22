extends TextureButton

var current_state: STATES:
	get = get_state, set = set_state
enum STATES {CHOICE, HIERACHY}
func get_state() -> STATES:
	return current_state
func set_state(value) -> void:
	current_state = value



var tag: String = String()
var data: Dictionary = Dictionary()

func initialize(_tag: String, _data: Dictionary) -> void:
	tag = _tag
	data = _data
	pass

func _ready() -> void:
	tooltip_title = tag.to_upper()
	pass



#yoinking this from system_map
@onready var custom_tooltip = preload("res://Scenes/Custom Tooltip/custom_tooltip.tscn")
var tooltip_title: String

func _make_custom_tooltip(for_text):
	var custom_tooltip_instance = custom_tooltip.instantiate()
	custom_tooltip_instance.initialize(tooltip_title, for_text)
	return custom_tooltip_instance
