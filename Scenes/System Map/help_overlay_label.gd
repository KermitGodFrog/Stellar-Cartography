extends Label

@export_node_path var track

func _process(_delta: float) -> void:
	if is_visible_in_tree() and track != null:
		var node = get_node(track)
		set_global_position(node.get_global_position() + (node.get_size() / 2) - (get_size() / 2))
	pass
