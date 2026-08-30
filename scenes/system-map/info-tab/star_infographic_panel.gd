extends PanelContainer

@onready var depictions_scroll = $v_scroll/depictions_scroll

var current_star_type: String:
	set(value):
		if current_star_type != value:
			current_star_type = value
			_on_current_star_type_changed(current_star_type)

func _on_current_star_type_changed(new_type: String) -> void:
	var depictions: Array[Node] = depictions_scroll.get_children()
	for star_type_depiction in depictions:
		if star_type_depiction.star_type == new_type:
			star_type_depiction.selected = true
		else:
			star_type_depiction.selected = false
	pass
