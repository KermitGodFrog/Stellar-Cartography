extends PanelContainer

@onready var title_label = $margin/vertical_scroll/horizontal_scroll/title_label
@onready var description_label = $margin/vertical_scroll/description_label
@onready var checkbox_texture_rect = $margin/vertical_scroll/horizontal_scroll/checkbox_panel/checkbox_texture_rect

var confirm_texture: Object
var denied_texture: Object

func initialize(title: String, description: String, state: objectiveAPI.STATES):
	match state:
		objectiveAPI.STATES.SUCCESS:
#			title_label.push_strikethrough()
#			title_label.push_color(Color.GREEN)
#			description_label.push_strikethrough()
			checkbox_texture_rect.set_texture(confirm_texture)
		objectiveAPI.STATES.FAILURE:
#			title_label.push_strikethrough()
#			title_label.push_color(Color.RED)
#			description_label.push_strikethrough()
			checkbox_texture_rect.set_texture(denied_texture)
	
	
	
	title_label.append_text(title)
	description_label.append_text(description)
	#title_label.pop_all()
	#description_label.pop_all()
	pass
