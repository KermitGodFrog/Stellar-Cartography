extends Node3D
class_name actor3D
#classes that inherit actor3D can only do so if they manipulates values at runtime and don't:
#a) do anything related to setup, which is managed by system_3d.gd
#b) do anything related to changing values on scope mode switch, which is managed by system_3d.gd

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
	ASTEROID_BELT, PULSAR_BEAM, #UTILITY
	AUDIO, MINE_SFX, PULSAR_BEAM_SFX #UTILITY
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
func is_in_all_cohorts(ca: Array[COHORTS]) -> bool:
	for c in ca:
		if not cohorts.has(c):
			return false
	return true
func is_in_any_cohorts(ca: Array[COHORTS]) -> bool:
	for c in ca:
		if cohorts.has(c):
			return true
	return false
func is_in_any_utility_cohorts() -> bool:
	return is_in_any_cohorts([actor3D.COHORTS.ASTEROID_BELT, actor3D.COHORTS.PULSAR_BEAM, actor3D.COHORTS.AUDIO])


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
