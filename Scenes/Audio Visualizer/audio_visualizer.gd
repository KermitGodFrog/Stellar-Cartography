extends Control

@onready var chimes = $chimes
@onready var pops = $pops
@onready var pulses = $pulses
@onready var storm = $storm
@onready var custom = $custom
@onready var visualizer_bg = $ui_container/visualizer_bg

var current_audio_matrix: Array = [] #CONTINUOUSLY UPDATED!!!
var locked_body_audio_matrix: Array = [] #used for button to reset back to locked body audio

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
	spectrum = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("Planetary SFX"), 0)
	pass

func _physics_process(delta):
	if custom.get_stream(): current_audio_matrix = [chimes.volume_db, pops.volume_db, pulses.volume_db, storm.volume_db, custom.get_stream(), custom.volume_db]
	else: current_audio_matrix = [chimes.volume_db, pops.volume_db, pulses.volume_db, storm.volume_db]
	
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

func _on_locked_body_updated(body: bodyAPI):
	if body.is_planet() and body.get_current_variation():
		var audio_variations = starSystemAPI.new().planet_type_audio_data.get(body.metadata.get("planet_type"))
		#starSystemAPI.new() ??????
		var audio_matrix = audio_variations.get(body.get_current_variation())
		
		if audio_matrix.size() == 4:
			initialize(audio_matrix[0], audio_matrix[1], audio_matrix[2], audio_matrix[3])
		elif audio_matrix.size() > 4:
			initialize(audio_matrix[0], audio_matrix[1], audio_matrix[2], audio_matrix[3], audio_matrix[4], audio_matrix[5])
		
		locked_body_audio_matrix = audio_matrix
	pass

func _on_locked_body_depreciated():
	if locked_body_audio_matrix == current_audio_matrix:
		deactivate()
	locked_body_audio_matrix.clear()
	pass







func _on_audio_visualizer_window_close_requested():
	owner.hide()
	pass
