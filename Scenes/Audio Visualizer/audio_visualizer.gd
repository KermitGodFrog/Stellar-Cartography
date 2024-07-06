extends Control

@onready var chimes = $chimes
@onready var pops = $pops
@onready var pulses = $pulses
@onready var storm = $storm
@onready var custom = $custom

var current_audio_matrix: Array = [] #CONTINUOUSLY UPDATED!!!
var locked_body_audio_matrix: Array = [] #used for button to reset back to locked body audio

var LOW_VAR = bodyAPI.VARIATIONS.LOW
var MED_VAR = bodyAPI.VARIATIONS.MEDIUM
var HIGH_VAR = bodyAPI.VARIATIONS.HIGH

var planet_type_audio_data = {
	"Chthonian": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Lava": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Hycean": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Desert": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Ocean": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Earth-like": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Ice": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Silicate": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Terrestrial": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Carbon": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Fire Dwarf": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Gas Dwarf": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Ice Dwarf": {LOW_VAR: [-80,10,0,-20], MED_VAR: [-80,5,0,-10], HIGH_VAR: [-80,0,0,10]},
	"Helium Dwarf": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Fire Giant": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Gas Giant": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Ice Giant": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]},
	"Helium Giant": {LOW_VAR: [0,0,0,0], MED_VAR: [0,0,0,0], HIGH_VAR: [0,0,0,0]}
}

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
		var audio_variations = planet_type_audio_data.get(body.metadata.get("planet_type"))
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

func _physics_process(delta):
	if custom.get_stream(): current_audio_matrix = [chimes.volume_db, pops.volume_db, pulses.volume_db, storm.volume_db, custom.get_stream(), custom.volume_db]
	else: current_audio_matrix = [chimes.volume_db, pops.volume_db, pulses.volume_db, storm.volume_db]
	pass

func _on_audio_visualizer_window_close_requested():
	owner.hide()
	pass
