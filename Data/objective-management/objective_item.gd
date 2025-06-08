extends PanelContainer

const default_title_color = Color.WHITE
const default_description_color = Color(0.75, 0.75, 0.75, 1.0)

@onready var title_label = $margin/vertical_scroll/horizontal_scroll/title_label
@onready var description_label = $margin/vertical_scroll/description_label
@onready var checkbox_texture_rect = $margin/vertical_scroll/horizontal_scroll/checkbox_panel/checkbox_texture_rect

var confirm_texture: Object
var denied_texture: Object

func initialize(title: String, description: String, state: objectiveAPI.STATES):
	title_label.set("theme_override_colors/default_color", default_title_color)
	description_label.set("theme_override_colors/default_color", default_description_color)
	
	if state != objectiveAPI.STATES.NONE:
		title_label.push_strikethrough()
		description_label.push_strikethrough()
		title_label.set("theme_override_colors/default_color", default_title_color.darkened(0.2))
		description_label.set("theme_override_colors/default_color", default_description_color.darkened(0.2))
	
	match state:
		objectiveAPI.STATES.SUCCESS:
			checkbox_texture_rect.set_texture(confirm_texture)
		objectiveAPI.STATES.FAILURE:
			checkbox_texture_rect.set_texture(denied_texture)
	
	title_label.append_text(title)
	description_label.append_text(description)
	
	title_label.pop_all()
	description_label.pop_all()
	pass
