extends Node
#this class plays ONE SHOT audio (called to by other scripts), plays generic UI click sounds, and music
#it does NOT play persistent sounds, which are handled locally by other scritps! (besides music, which is persistent)

var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		_pause_mode = value
		_on_pause_mode_changed(value)
signal queuePauseMode(new_mode: game_data.PAUSE_MODES)
signal setPauseMode(new_mode: game_data.PAUSE_MODES)
func _on_pause_mode_changed(value):
	match value:
		game_data.PAUSE_MODES.NONE:
			music_linear_volume_target = 1.0
		_:
			music_linear_volume_target = 0.0
	pass

@onready var UI_click_generic = preload("res://Sound/SFX/UI_click_generic.tres")
@onready var music = $music
@onready var intermission = $intermission

#for ducking music when audio visualizer is open!
var audio_visualizer_visible: bool = false:
	set(value):
		audio_visualizer_visible = value
		_on_av_visibility_changed(value)
func _on_av_visibility_changed(value):
	match value:
		true:
			music_linear_volume_target = 0.0
		false:
			music_linear_volume_target = 1.0
	pass

var music_linear_volume_target: float = 1.0

func _process(delta):
	#print("MUSIC LINEAR VOLUME TARGET: ", music_linear_volume_target)
	#print("MUSIC REAL VOLUME (DB): ", music.volume_db)
	music.volume_db = maxf(-80, move_toward(music.volume_db, linear_to_db(music_linear_volume_target), 100.0 * delta))
	pass

func _ready():
	music.connect("finished", _on_music_finished)
	intermission.connect("timeout", _on_intermission_finished)
	_on_music_finished()
	
	for node in get_tree().get_nodes_in_group("playUIClickSFX"):
		if node is Button:
			node.connect("pressed", _on_play_once_UI_click_SFX)
		elif node is TabContainer:
			node.connect("tab_button_pressed", _on_play_once_UI_click_SFX.unbind(1))
		elif node is ItemList:
			node.connect("item_selected", _on_play_once_UI_click_SFX.unbind(1))
	pass

func _on_music_finished() -> void:
	intermission.set_wait_time(
		maxi(0, randfn(60.0, 15.0))
		)
	intermission.start()
	pass

func _on_intermission_finished() -> void:
	if _pause_mode == game_data.PAUSE_MODES.NONE:
		music.play()
	else:
		_on_music_finished()
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
