extends Control

@onready var item_scene = preload("uid://6rp5mwt3o17w")
@onready var spawn_scroll = $panel/margin/actions_items_split/scroll/spawn_scroll


func _on_visibility_changed() -> void:
	if visible:
		update_history()
	pass

func update_history() -> void:
	for item in spawn_scroll.get_children():
		item.queue_free()
	
	if FileAccess.file_exists("user://stellar_cartographer_history.csv"):
		var history = FileAccess.open("user://stellar_cartographer_history.csv", FileAccess.READ)
		var current_line: int = 0
		var eof_override: bool = true
		
		while (not history.eof_reached()) or eof_override:
			if history.eof_reached():
				eof_override = false
			var line = history.get_csv_line()
			
			current_line += 1
			
			if line.is_empty(): continue
			
			var new_item = item_scene.instantiate()
			new_item.connect("ready", _on_history_item_ready.bind(new_item, line, current_line))
			spawn_scroll.add_child(new_item)
			
		
		history.close()
	
	
	pass

func _on_history_item_ready(item: Node, line: PackedStringArray, current_line: int) -> void:
	item.create_from_csv(line, current_line)
	pass
