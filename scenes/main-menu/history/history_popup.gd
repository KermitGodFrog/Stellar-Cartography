extends Control

signal returnButtonPressed

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
		var items: Array[Node] = []
		var item_count: int = 0
		
		while not history.eof_reached():
			var line = history.get_csv_line()
			
			if line.is_empty(): continue
			elif line[0] == String(): continue
			
			item_count += 1
			
			var new_item = item_scene.instantiate()
			new_item.connect("ready", _on_history_item_ready.bind(new_item, line, item_count))
			items.append(new_item)
		
		history.close()
		
		items.reverse()
		for item in items:
			spawn_scroll.add_child(item)
	pass

func _on_history_item_ready(item: Node, line: PackedStringArray, item_count: int) -> void:
	item.create_from_csv(line, item_count)
	pass


func _on_history_return_button_pressed() -> void:
	emit_signal("returnButtonPressed")
	pass 
