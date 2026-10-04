extends Node
#this class plays ONE SHOT audio (called to by other scripts), plays generic UI click sounds, and music
#it does NOT play persistent sounds, which are handled locally by other scritps! (besides music, which is persistent)

var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		_pause_mode = value
		_on_pause_mode_changed(value)
signal queuePauseMode(new_mode: game_data.PAUSE_MODES)
signal setPauseMode(new_mode: game_data.PAUSE_MODES)
func _on_pause_mode_changed(_value):
	pass

@onready var UI_click_generic = preload("uid://bxhmolsyar7ei")
@onready var music = $music
@onready var intermission = $intermission
@onready var radio_handler =  $radioHandler

var music_linear_volume_target: float = 1.0
var enable_music_criteria: Dictionary = {}
var blur_music_criteria: Dictionary = {}
var music_queue: Array[String] = []

enum AMBIENCE_TYPES {GAME, CREATE_MENU}
var ambience_type: AMBIENCE_TYPES = AMBIENCE_TYPES.GAME
var intermission_mean: float = 120.0
var intermission_stdev: float = 30.0



func _process(delta):
	radio_handler.enable_radio = _pause_mode == game_data.PAUSE_MODES.NONE
	enable_music_criteria["pause_mode_none"] = _pause_mode == game_data.PAUSE_MODES.NONE
	
	var enable_music: bool = enable_music_criteria.values().all(equal_to_true) and not enable_music_criteria.is_empty()
	match enable_music:
		true:
			music_linear_volume_target = 1.0
		false:
			music_linear_volume_target = 0.0
	
	var music_bus_idx := AudioServer.get_bus_index("Music")
	var eq_effect := AudioServer.get_bus_effect(music_bus_idx, 0)
	var blur_music: bool = blur_music_criteria.values().all(equal_to_true) and not blur_music_criteria.is_empty()
	match blur_music:
		true:
			for idx in range(3, 6):
				eq_effect.set_band_gain_db(idx, lerpf(eq_effect.get_band_gain_db(idx), -60, 5.0 * delta))
		false:
			for idx in range(3, 6):
				eq_effect.set_band_gain_db(idx, lerpf(eq_effect.get_band_gain_db(idx), 0.0, 5.0 * delta))
	
	#print("MUSIC LINEAR VOLUME TARGET: ", music_linear_volume_target)
	#print("MUSIC REAL VOLUME (DB): ", music.volume_db)
	music.volume_db = maxf(-80, move_toward(music.volume_db, linear_to_db(music_linear_volume_target), 100.0 * delta))
	
	if not music.is_playing():
		if music_queue.size() > 0:
			if _pause_mode == game_data.PAUSE_MODES.NONE:
				var new_path = music_queue.pop_front()
				print("(AUDIO HANDLER) PLAYING NEW MUSIC PATH: ", new_path)
				var new = load(new_path)
				music.set_stream(new)
				music.play()
	pass

func equal_to_true(element: bool) -> bool:
	return element == true



func _ready():
	intermission.connect("timeout", _on_intermission_timeout)
	restart_intermission()
	
	var music_bus_idx := AudioServer.get_bus_index("Music")
	var eq_effect := AudioServer.get_bus_effect(music_bus_idx, 0)
	for idx in range(0, 6):
		eq_effect.set_band_gain_db(idx, 0.0)
	
	for node in get_tree().get_nodes_in_group("playUIClickSFX"):
		if node is Button:
			node.connect("pressed", _on_play_once_UI_click_SFX)
		elif node is TabContainer:
			node.connect("tab_button_pressed", _on_play_once_UI_click_SFX.unbind(1))
		elif node is ItemList:
			node.connect("item_selected", _on_play_once_UI_click_SFX.unbind(1))
	pass








func restart_intermission() -> void:
	intermission.set_wait_time(
		maxi(0, randfn(intermission_mean, intermission_stdev))
		)
	intermission.start()
	pass

func _on_intermission_timeout() -> void:
	if _pause_mode == game_data.PAUSE_MODES.NONE:
		match ambience_type:
			AMBIENCE_TYPES.GAME:
				music_queue.append("res://sound/music/ambience.tres")
			AMBIENCE_TYPES.CREATE_MENU:
				music_queue.append("res://sound/music/create_menu_ambience.tres")
	restart_intermission()
	pass








func _on_play_once_UI_click_SFX() -> void:
	play_once(UI_click_generic, -12.0, "SFX")
	pass

func play_once(stream: AudioStream, volume_db: float = 0.0, bus: StringName = "Master"):
	var player = AudioStreamPlayer.new()
	player.set_stream(stream)
	player.set_volume_db(volume_db)
	player.set_bus(bus)
	player.set_autoplay(true)
	player.connect("finished", _on_play_once_player_finished.bind(player))
	add_child(player)
	pass

func _on_play_once_player_finished(player: AudioStreamPlayer) -> void:
	player.call_deferred("queue_free")
	pass

func queue_music(path: String) -> void:
	music_queue.append(path)
	print("(AUDIO HANDLER) PATH ADDED TO MUSIC QUEUE: ", path)
	pass


func plot_radio(h: radioHelper) -> void:
	radio_handler._plot_radio(h)
	pass
