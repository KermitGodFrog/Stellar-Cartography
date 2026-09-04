extends "res://instantiated-scenes/custom-tooltip/custom_tooltip_control.gd"

signal activated(_mutation: worldAPI.MUTATION_ID, _current_list: LISTS)

enum INIT_TYPES {DISPLAY, EDIT, DISPLAY_WITH_OFFSET}
enum LISTS {UNINSTALLED, INSTALLED}
var init_type: INIT_TYPES = INIT_TYPES.DISPLAY
var current_list: LISTS = LISTS.UNINSTALLED

var mutation: worldAPI.MUTATION_ID

@onready var offset_label = $mutation_margin/mutation_scroll/offset_panel/offset_label
@onready var title_label = $mutation_margin/mutation_scroll/info_scroll/title_label
@onready var headline_label = $mutation_margin/mutation_scroll/info_scroll/headline_label
@onready var offset_panel = $mutation_margin/mutation_scroll/offset_panel
@onready var mark_texture = $mutation_margin/mark_texture

func initialize(_mutation: worldAPI.MUTATION_ID) -> void:
	mutation = _mutation
	
	var data: Dictionary = worldAPI.mutation_data.get(mutation)
	
	title_label.set_text(data.get("title"))
	headline_label.set_text(data.get("headline"))
	
	var points_offset = data.get("points_offset")
	if points_offset > 0:
		offset_label.set_text("+%d" % points_offset)
		offset_label.set("theme_override_colors/font_color", Color.GREEN)
	elif points_offset < 0:
		offset_label.set_text("%d" % points_offset)
		offset_label.set("theme_override_colors/font_color", Color.RED)
	else:
		offset_label.set_text("%d" % points_offset)
		offset_label.set("theme_override_colors/font_color", Color.YELLOW)
	
	
	tooltip_title = data.get("title")
	var combined_tooltip: String = String()
	combined_tooltip += "[i]%s[/i]" % data.get("description")
	combined_tooltip += "\n\n[color=lightyellow]Effect:[/color]\n%s" % data.get("effect")
	
	match data.get("type"):
		"POSITIVE":
			mark_texture.modulate = Color.DARK_GREEN
			combined_tooltip += "\n[color=darkgreen](%s)[/color]" % data.get("type")
		"NEGATIVE":
			mark_texture.modulate = Color.DARK_RED
			combined_tooltip += "\n[color=darkred](%s)[/color]" % data.get("type")
		"NEUTRAL":
			mark_texture.modulate = Color.DARK_GOLDENROD
			combined_tooltip += "\n[color=dark_goldenrod](%s)[/color]" % data.get("type")
	
	if init_type == INIT_TYPES.EDIT:
		combined_tooltip += "\n\n[img]res://graphics/shared/mouse/mouse_left.png[/img] Install or Uninstall"
	tooltip_text = combined_tooltip
	
	if init_type in [INIT_TYPES.EDIT, INIT_TYPES.DISPLAY_WITH_OFFSET]:
		offset_panel.show()
	else:
		offset_panel.hide()
	
	match init_type:
		INIT_TYPES.EDIT:
			set("mouse_default_cursor_shape", CursorShape.CURSOR_POINTING_HAND)
		_:
			set("mouse_default_cursor_shape", CursorShape.CURSOR_ARROW)
	pass

func _on_gui_input(event: InputEvent) -> void:
	if init_type == INIT_TYPES.EDIT:
		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_LEFT:
				emit_signal("activated", mutation, current_list)
	pass
