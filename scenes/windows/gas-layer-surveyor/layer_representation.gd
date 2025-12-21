extends TextureButton
enum LISTS {HIERACHY, CHOICES}
enum ACTIONS {SWITCH_COLUMN, VIEW_IN_ENCYCLOPEDIA}
enum STATUSES {NONE, CONFIRMED, DENIED}

signal activated(_tag: String, _list: LISTS, _action: ACTIONS)

@onready var confirm = preload("uid://cqooj3po86k13")
@onready var denied = preload("uid://bm60fxptpfl4x")
@onready var status_texture = $status_texture
@onready var status_label = $status_label
@onready var cover = $cover

var current_list: LISTS
var current_status: STATUSES
var tag: String = String()
var data: Dictionary = Dictionary()
var cover_path: String = String()

func initialize(_tag: String, _data: Dictionary, _list: LISTS, _cover_path: String) -> void:
	tag = _tag
	data = _data
	current_list = _list
	cover_path = _cover_path
	pass

func _ready() -> void:
	set_status(STATUSES.NONE)
	tooltip_title = tag.to_upper()
	texture_normal.gradient.set_color(0, data.get("bg_color", Color.WHITE))
	texture_normal.gradient.set_color(1, data.get("fog_albedo", Color.WHITE))
	if cover_path.is_absolute_path():
		cover.set_texture(load(cover_path))
	pass



#yoinking this from system_map
@onready var custom_tooltip = preload("uid://cer7wk3ixuyb6")
var tooltip_title: String
func _make_custom_tooltip(for_text):
	var custom_tooltip_instance = custom_tooltip.instantiate()
	custom_tooltip_instance.initialize(tooltip_title, for_text)
	return custom_tooltip_instance



func _on_gui_input(event: InputEvent) -> void:
	if current_status == STATUSES.NONE:
		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				emit_signal("activated", tag, current_list, ACTIONS.SWITCH_COLUMN)
			if event.button_index == MOUSE_BUTTON_RIGHT:
				emit_signal("activated", tag, current_list, ACTIONS.VIEW_IN_ENCYCLOPEDIA)
	pass



func set_status(_status: STATUSES, nanites: int = 0) -> void:
	current_status = _status
	match _status:
		STATUSES.NONE:
			status_texture.hide()
			status_label.hide()
		STATUSES.CONFIRMED:
			status_texture.show()
			status_label.show()
			status_texture.set_texture(confirm)
			status_label.set_text("+%.fn" % nanites)
		STATUSES.DENIED:
			status_texture.show()
			status_label.hide()
			status_texture.set_texture(denied)
	pass
