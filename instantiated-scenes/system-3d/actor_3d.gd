extends Node3D
class_name actor3D

@onready var mesh = $mesh
@onready var sprite = $sprite
@onready var audio = $audio
@onready var flyby = $flyby

var identifier: int:
	get = get_identifier, set = set_identifier
func get_identifier() -> int:
	return identifier
func set_identifier(value) -> void:
	identifier = value
	pass

#used for RUNTIME CHANGES TO ACTORS - NOT the initial setup, which is managed entirely by system_3d!!
enum COHORTS {
	ORBIT_BODY, UNIT_BODY,
	CIRCULAR_BODY, GLINT_BODY, CUSTOM_BODY,
	AI_UNIT, MINE_UNIT,
	ASTEROID_BELT, PULSAR_BEAM, 
	AUDIO, MINE_SFX, PULSAR_BEAM_SFX
}
var cohorts: Array[COHORTS] = []
func add_cohort(c: COHORTS) -> void:
	if not is_in_cohort(c):
		cohorts.append(c)
	pass
func remove_cohort(c: COHORTS) -> void:
	if is_in_cohort(c):
		cohorts.erase(c)
	pass
func is_in_cohort(c: COHORTS) -> bool:
	if cohorts.has(c):
		return true
	return false

var do_mesh: bool = false:
	set(value):
		do_mesh = value
		if value == true:
			pre_update_mesh()
var do_sprite: bool = false:
	set(value):
		do_sprite = value
		if value == true:
			pre_update_sprite()
var do_audio: bool = false:
	set(value):
		do_audio = value
		if value == true:
			pre_update_audio()
var do_flyby: bool = false:
	set(value):
		do_flyby = value
		flyby.set_playing(value)

func initialize(_do_flyby: bool, _mesh_variables: Dictionary = {}, _sprite_variables: Dictionary = {}, _audio_variables: Dictionary = {}) -> void:
	do_flyby = _do_flyby
	var aspect_pairs = { 
		"do_mesh": _mesh_variables,
		"do_sprite": _sprite_variables,
		"do_audio": _audio_variables
	}
	for aspect in aspect_pairs:
		set(aspect, not aspect_pairs[aspect].is_empty())
	for variables in [_mesh_variables, _sprite_variables, _audio_variables]:
		for v in variables:
			if variables == _mesh_variables:
				mesh.set(v, variables[v])
			elif variables == _sprite_variables:
				sprite.set(v, variables[v])
			elif variables == _audio_variables:
				audio.set(v, variables[v])
	pass

func pre_update_mesh() -> void:
	for c in cohorts:
		match c: #must be in order of COHORTS enum values
			COHORTS.CIRCULAR_BODY:
				mesh.set_mesh(SphereMesh.new())
				mesh.set_surface_material_override(0, StandardMaterial3D.new())
				mesh.get_surface_material_override().set("emission_enabled", true)
			COHORTS.MINE_UNIT:
				mesh.set_mesh(load("uid://bgfq0xrhripbw"))
	pass

func pre_update_sprite() -> void:
	for c in cohorts: 
		match c: #must be in order of COHORTS enum values
			COHORTS.GLINT_BODY:
				sprite.set_pixel_size(starSystemAPI.get_default_radius_solar_radii())
				sprite.set_texture(load("uid://c236x4bwtcifq"))
	pass

func pre_update_audio() -> void:
	for c in cohorts:
		match c: #must be in order of COHORTS enum values
			pass
	pass





func _on_scope_mode_changed(new_mode: playerAPI.SCOPE_MODES) -> void:
	for c in cohorts:
		match c: #must be in order of COHORTS enum values
			COHORTS.GLINT_BODY:
				match new_mode:
					playerAPI.SCOPE_MODES.VIS:
						sprite.set_texture(load("uid://kxo1pkvmhml4"))
					playerAPI.SCOPE_MODES.RAD:
						sprite.set_texture(load("uid://c236x4bwtcifq"))
	pass
