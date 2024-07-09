extends Control

@onready var chimes = $chimes
@onready var pops = $pops
@onready var pulses = $pulses
@onready var storm = $storm
@onready var custom = $custom
@onready var visualizer_bg = $ui_container/visualizer_bg
@onready var saved_audio_profiles_list = $ui_container/saved_audio_profiles_list
@onready var recording_label = $ui_container/visualizer_bg/recording_label

var current_audio_profile: Array = [] #CONTINUOUSLY UPDATED!!!
var locked_body_audio_profile: Array = [] #used for button to reset back to locked body audio

var saved_audio_profile_helpers: Array[audioProfileHelper] = []

var LOW_VAR = bodyAPI.VARIATIONS.LOW
var MED_VAR = bodyAPI.VARIATIONS.MEDIUM
var HIGH_VAR = bodyAPI.VARIATIONS.HIGH

#VISUALIZER STUFF \/\/\/\/\/
const VU_COUNT = 16
const FREQ_MAX = 11050.0
var WIDTH: int = 600
var HEIGHT: int = 100
const MIN_DB = 60
var spectrum

func _ready():
	saved_audio_profiles_list.connect("saveAudioProfileHelper", _on_play_audio_profile_helper) #saveAudioProfileHelper because it inherits from class that uses that
	spectrum = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("Planetary SFX"), 0)
	pass

func _physics_process(delta):
	#print_debug("CURRENT AUDIO PROFILE + LOCKED BODY AUDIO PROFILE: ", current_audio_profile, " ", locked_body_audio_profile)
	if custom.get_stream(): current_audio_profile = [chimes.volume_db, pops.volume_db, pulses.volume_db, storm.volume_db, custom.get_stream(), custom.volume_db]
	else: current_audio_profile = [chimes.volume_db, pops.volume_db, pulses.volume_db, storm.volume_db]
	
	if owner.is_visible(): AudioServer.set_bus_mute(AudioServer.get_bus_index("Planetary SFX"), false)
	else: AudioServer.set_bus_mute(AudioServer.get_bus_index("Planetary SFX"), true)
	
	#visualizer stuff
	WIDTH = owner.size.x
	HEIGHT = owner.size.y / 4
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
		draw_rect(Rect2(w * i-w, HEIGHT - height, w, height), Color.WHITE)
		prev_hz = hz
	pass


func initialize(chimes_db: float, pops_db: float, pulses_db: float, storm_db: float, custom_audio_stream = null, custom_db = null):
	var pairs = [[chimes, chimes_db], [pops, pops_db], [storm, storm_db]]
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


func _on_popup():
	saved_audio_profiles_list.initialize(saved_audio_profile_helpers)
	pass

func _on_play_audio_profile_helper(helper: audioProfileHelper):
	var audio_profile = helper.audio_profile
	if audio_profile.size() == 4:
		initialize(audio_profile[0], audio_profile[1], audio_profile[2], audio_profile[3])
	elif audio_profile.size() > 4:
		initialize(audio_profile[0], audio_profile[1], audio_profile[2], audio_profile[3], audio_profile[4], audio_profile[5])
	pass

func _on_locked_body_updated(body: bodyAPI):
	if body.is_planet() and body.get_current_variation():
		var audio_variations = starSystemAPI.new().planet_type_audio_data.get(body.metadata.get("planet_type"))
		#starSystemAPI.new() ??????
		var audio_profile = audio_variations.get(body.get_current_variation())
		var helper = audioProfileHelper.new()
		helper.body = body
		helper.audio_profile = audio_profile
		_on_play_audio_profile_helper(helper)
		locked_body_audio_profile = audio_profile
		
		recording_label.show()
	else:
		deactivate()
	pass

func _on_locked_body_depreciated():
	print_debug("locked body depreciated")
	if locked_body_audio_profile == current_audio_profile:
		deactivate()
	locked_body_audio_profile.clear()
	
	recording_label.hide()
	pass

func _on_clear_button_pressed():
	deactivate()
	pass

func _on_reset_to_locked_button_pressed():
	current_audio_profile = locked_body_audio_profile
	pass

func _on_audio_visualizer_window_close_requested():
	owner.hide()
	pass



