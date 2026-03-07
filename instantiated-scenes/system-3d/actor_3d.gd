extends Node3D
class_name actor3D

@onready var mesh_instance = $mesh_instance
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

func initialize(_mesh_instance_variables: Dictionary = {}, _sprite_variables: Dictionary = {}, _audio_variables: Dictionary = {}, _flyby_variables: Dictionary = {}) -> void:
	sprite.set_pixel_size(starSystemAPI.get_default_radius_solar_radii())
	for variables in [_mesh_instance_variables, _sprite_variables, _audio_variables, _flyby_variables]:
		for v in variables:
			if variables == _mesh_instance_variables:
				mesh_instance.set(v, variables[v])
			elif variables == _sprite_variables:
				sprite.set(v, variables[v])
			elif variables == _audio_variables:
				audio.set(v, variables[v])
			elif variables == _flyby_variables:
				flyby.set(v, variables[v])
	pass

func _on_scope_mode_changed(_new_mode: playerAPI.SCOPE_MODES) -> void:
	pass
