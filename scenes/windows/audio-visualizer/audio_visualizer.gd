extends Control

signal removeSavedAudioProfile(helper: audioProfileHelper)

@onready var chimes = $chimes
@onready var pops = $pops
@onready var pulses = $pulses
@onready var storm = $storm
@onready var custom = $custom
@onready var visualizer_bg = $scroll/visualizer_bg
@onready var saved_audio_profiles_list = $scroll/scroll/profiles_panel/profiles_margin/profiles_scroll/saved_audio_profiles_list
@onready var body_name_label = $scroll/visualizer_bg/body_name_label
@onready var storage_ratio_label = $scroll/scroll/profiles_panel/profiles_margin/profiles_scroll/storage_container/storage_ratio_label
@onready var storage_progress_bar = $scroll/scroll/profiles_panel/profiles_margin/profiles_scroll/storage_container/storage_progress_bar
@onready var no_current_planet_bg = $scroll/visualizer_bg/no_current_planet_bg

var locked_body: bodyAPI = null:
	set(value):
		locked_body = value
		_on_locked_body_updated(locked_body)

var current_audio_profile: audioProfileHelper #CONTINUOUSLY UPDATED!!!
var saved_audio_profiles: Array[audioProfileHelper] = []
var saved_audio_profiles_size_matrix: Array #for storage label / progress bar

var LOW_VAR = planetBodyAPI.VARIATIONS.LOW
var MED_VAR = planetBodyAPI.VARIATIONS.MEDIUM
var HIGH_VAR = planetBodyAPI.VARIATIONS.HIGH 

#VISUALIZER STUFF \/\/\/\/\/
const VU_COUNT = 16
const FREQ_MAX = 11050.0
var WIDTH: int = 600
var HEIGHT: int = 100
const MIN_DB = 60
var spectrum

func _ready():
	saved_audio_profiles_list.connect("playSavedAudioProfile", _on_play_audio_profile)
	saved_audio_profiles_list.connect("removeSavedAudioProfile", _on_remove_saved_audio_profile)
	spectrum = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("Planetary SFX"), 0)
	pass

func _physics_process(_delta):
	if owner.is_visible():
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Planetary SFX"), false)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Planetary SFX"), true)
	
	if locked_body:
		no_current_planet_bg.hide()
	else:
		no_current_planet_bg.show()
	
	#visualizer stuff
	WIDTH = owner.size.x
	HEIGHT = owner.size.y / 4
	
	#display stuff
	if current_audio_profile: body_name_label.set_text(current_audio_profile.body.get_display_name())
	if saved_audio_profiles_size_matrix: 
		storage_ratio_label.set_text(str("(", saved_audio_profiles_size_matrix.front(), "/", saved_audio_profiles_size_matrix.back(), " PROFILES)"))
		storage_progress_bar.set_max(saved_audio_profiles_size_matrix.back())
		storage_progress_bar.set_value(saved_audio_profiles_size_matrix.front())
	
	queue_redraw()
	pass

func _draw():
	var w = WIDTH / VU_COUNT
	var prev_hz = 0
	for i in range(1, VU_COUNT+1):
		var hz = i * FREQ_MAX / VU_COUNT;
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height = energy * HEIGHT
		draw_rect(Rect2(w * i-w, HEIGHT - height, w, height), Color("#3c9371"))
		prev_hz = hz
	pass

func initialize(chimes_db: float, pops_db: float, pulses_db: float, storm_db: float, custom_audio_stream = null, custom_db = null): #not going to have custom audio streams (atleast in the long future), so this is useless
	var pairs = [[chimes, chimes_db], [pops, pops_db], [pulses, pulses_db], [storm, storm_db]]
	for sound in pairs:
		sound.front().set_volume_db(sound.back())
		sound.front().play(global_data.get_randf(0.0, sound.front().get_stream().get_length()))
	if custom_audio_stream and custom_db:
		custom.set_stream(custom_audio_stream)
		custom.set_volume_db(custom_db)
		custom.play(global_data.get_randf(0.0, custom.stream.get_length()))
	pass

func deactivate():
	var all_sfx = [chimes, pops, pulses, storm, custom]
	for sfx in all_sfx:
		sfx.stop()
	pass

func _on_play_audio_profile(helper: audioProfileHelper):
	current_audio_profile = helper
	var mix = helper.mix
	if mix.size() == 4:
		initialize(mix[0], mix[1], mix[2], mix[3])
	elif mix.size() > 4:
		initialize(mix[0], mix[1], mix[2], mix[3], mix[4], mix[5])
	pass

func _on_remove_saved_audio_profile(helper: audioProfileHelper):
	emit_signal("removeSavedAudioProfile", helper)
	_on_popup()
	pass

func _on_locked_body_updated(body: bodyAPI):
	if (body.get_type() == starSystemAPI.BODY_TYPES.PLANET) and (body.is_known()): 
		if body.get_current_variation() != -1:
			var audio_variations = starSystemAPI.new().planet_type_audio_data.get(body.metadata.get("planet_type"))
			var mix = audio_variations.get(body.get_current_variation())
			var helper = audioProfileHelper.new()
			helper.body = body
			helper.mix = mix
			_on_play_audio_profile(helper)
	else:
		current_audio_profile = null
		deactivate()
		body_name_label.set_text(String())
	pass

func _on_clear_button_pressed():
	current_audio_profile = null
	deactivate()
	body_name_label.set_text("")
	pass

func _on_popup():
	saved_audio_profiles_list.initialize(saved_audio_profiles)
	pass



func _on_audio_visualizer_window_close_requested():
	owner.hide()
	pass

#PICKER UTILITY \/\/\/\/\/
#if follow_body and follow_body.is_known(): 
#	if follow_body.get_type() == starSystemAPI.BODY_TYPES.PLANET: 
#		if follow_body.get_current_variation() != -1:
#			var data_for_planet_type = system.planet_type_data.get(follow_body.metadata.get("planet_type"))
#			var variation_class = data_for_planet_type.get("variation_class")
#			if variation_class != null and (follow_body.metadata.get("missing_AO", false) == true):
#				picker_label.show()
#				picker_button.show()
#				picker_label.set_text(str(variation_class.capitalize(), " (AUDIO VISUALIZER): "))
#				if follow_body.get_guessed_variation() != -1:
#					picker_button.select(follow_body.get_guessed_variation())
#				else: picker_button.select(-1)
#			else:
#				picker_label.hide()
#				picker_button.hide()
#		else:
#			picker_label.hide()
#			picker_button.hide()
#	else:
#		picker_label.hide()
#		picker_button.hide()
#else:
#	picker_label.hide()
#	picker_button.hide() #NEED TO FIX THIS ATROCITY AT SOME POINT!!!!

#func _on_picker_button_item_selected(index):
#	if follow_body.get_type() == starSystemAPI.BODY_TYPES.PLANET:
#		follow_body.set_guessed_variation(index)
#	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "AV_picker_select")
#	pass
