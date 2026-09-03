extends Label

@export_node_path("LineEdit") var line_edit_path

func _ready() -> void:
	get_node(line_edit_path).text_changed.connect(_on_line_edit_text_changed.unbind(1))
	_on_line_edit_text_changed()
	pass

func _on_line_edit_text_changed() -> void:
	var line_edit = get_node(line_edit_path) as LineEdit
	set_text("%0*d/%.f" % [str(line_edit.max_length).length(), line_edit.text.length(), line_edit.max_length]) 
	pass
