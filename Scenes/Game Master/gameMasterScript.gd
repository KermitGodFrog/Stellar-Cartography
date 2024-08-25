extends Node

func _ready():
	global_data.change_scene.connect(_change_scene)
	global_data.change_scene.emit("res://Scenes/Main Menu/main_menu.tscn")
	pass

func _change_scene(path_to_scene, with_init_type = null):
	for child in get_children():
		call_deferred("remove_child", child)
		#remove_child(child)
		child.queue_free()
	
	var new_scene = load(path_to_scene).instantiate()
	
	if with_init_type != null: new_scene.init_type = with_init_type
	
	add_child(new_scene)
	pass

