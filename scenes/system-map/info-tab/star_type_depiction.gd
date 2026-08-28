extends "res://scenes/system-map/custom_tooltip_control.gd"

@onready var selected_stylebox = preload("uid://bb2dqri2dtnyy")
@onready var unselected_stylebox = preload("uid://bkbumqb0aeek1")

@onready var panel = $panel
@onready var label = $label

#this stuff will have to be updated if star types are added or changed!
@export_enum("M", "K", "G", "F", "A", "B", "O", "Pulsar") var star_type: String:
	set(value):
		star_type = value
		update_display()
const star_display_data := { 
	"M": {"panel_color": Color.LIME},
	"K": {"panel_color": Color.LIME_GREEN},
	"G": {"panel_color": Color.DARK_GREEN},
	"Pulsar": {"panel_color": Color.DARK_GREEN, "label_alias": "P"},
	"F": {"panel_color": Color.YELLOW},
	"A": {"panel_color": Color.ORANGE_RED},
	"B": {"panel_color": Color.RED},
	"O": {"panel_color": Color.DARK_RED}
}
@export var selected: bool:
	set(value):
		selected = value
		update_display()

func update_display() -> void:
	if is_node_ready():
		var type_data: Dictionary = star_display_data.get(star_type)
		if selected:
			panel.set_self_modulate(type_data.get("panel_color").lightened(0.25))
			set("theme_override_styles/panel", selected_stylebox)
		else:
			panel.set_self_modulate(type_data.get("panel_color"))
			set("theme_override_styles/panel", unselected_stylebox)
		label.set_text(type_data.get("label_alias", star_type))
		if star_type == "Pulsar":
			tooltip_title = "%s Star" % star_type
		else:
			tooltip_title = "Type '%s' Star" % star_type
		tooltip_text = starSystemAPI.star_descriptions.get(star_type)
	pass
