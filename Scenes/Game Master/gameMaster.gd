extends Node

const game_path = "res://Scenes/Game/game.tscn" #not used to load the game, thankfully, just to set whether tips should be shown!
const main_menu_path = "res://Scenes/Main Menu/main_menu.tscn"
const loading_screen_path = "res://Scenes/Loading Screen/loading_screen.tscn"
const exclude = ["achievementManager"]

var _current_path_to_scene: String = ""
var _current_init_args: Dictionary = {}
var _current_loading_instance: Node #loading screen
var _current_load_confirmation: bool = false
var progress: Array[float] = []

func _ready():
	global_data.change_scene.connect(_change_scene)
	global_data.change_scene.emit(main_menu_path)
	pass

func _change_scene(path_to_scene, init_args: Dictionary = {}): #init args: {"init_type": thing, "init_data": [thing, thing]}
	for child in get_children():
		if exclude.has(child.name):
			continue
		call_deferred("remove_child", child)
		child.queue_free()
	
	var loading_instance = load(loading_screen_path).instantiate()
	loading_instance.connect("load_confirmation", _on_loading_instance_load_confirmation)
	add_child(loading_instance)
	await loading_instance.is_node_ready()
	if path_to_scene != game_path:
		loading_instance.disable_tips()
	
	var error = ResourceLoader.load_threaded_request(path_to_scene)
	if error != OK:
		default_failure_contingency(error, null)
	
	_current_path_to_scene = path_to_scene
	_current_init_args = init_args
	_current_loading_instance = loading_instance
	pass

func _process(_delta):
	if not _current_path_to_scene.is_empty():
		var status = ResourceLoader.load_threaded_get_status(_current_path_to_scene, progress)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				
				if _current_path_to_scene == game_path:
					if not _current_load_confirmation:
						_current_loading_instance.show_continue_popup()
						return
				
				var new_scene: PackedScene = ResourceLoader.load_threaded_get(_current_path_to_scene) as PackedScene
				var new_scene_instance = new_scene.instantiate()
				
				for arg in _current_init_args:
					new_scene_instance.set(arg, _current_init_args.get(arg))
				
				add_child(new_scene_instance)
				
				call_deferred("remove_child", _current_loading_instance)
				_current_loading_instance.queue_free()
				
				global_data.scene_changed.emit(_current_path_to_scene)
				
				reset_all_current()
				
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				if _current_loading_instance:
					if _current_loading_instance.is_node_ready():
						_current_loading_instance.update_progress(progress[0] * 100.0)
			_:
				default_failure_contingency(null, status)
	pass

func default_failure_contingency(error_code = null, thread_load_status_code = null) -> void:
	push_error("Thread load failure, default contingency.", " (error code: ", error_code, ", thread load status code: ", thread_load_status_code, ")")
	print("(GAME MASTER) WAS LOADING SCENE PATH: ", _current_path_to_scene)
	print("(GAME MASTER) WAS LOADING WITH INIT ARGS: ", _current_init_args)
	print("(GAME MASTER) FAILED LOADING AT PROGRESS: ", progress)
	
	reset_all_current()
	global_data.change_scene.emit(main_menu_path)
	pass

func reset_all_current() -> void:
	_current_path_to_scene = ""
	_current_init_args = {}
	_current_loading_instance = null
	_current_load_confirmation = false
	pass

func _on_loading_instance_load_confirmation() -> void:
	_current_load_confirmation = true
	pass
