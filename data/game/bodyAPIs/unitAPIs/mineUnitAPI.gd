extends unitBodyAPI
class_name mineUnitAPI

var exclusion_radius_points: PackedVector2Array = [] # set by system_map.gd

const max_detonation_time: float = 2.0
@export_storage var detonation_time: float = 0.0
var detonation_time_index: float = 0.0:
	get():
		return remap(detonation_time, 0.0, max_detonation_time, 0.0, 1.0)

func tick_detonation_time(up: bool, delta):
	if up:
		detonation_time = minf(max_detonation_time, detonation_time + delta)
	else:
		detonation_time = maxf(0.0, detonation_time - (delta / 16))
	pass

func can_detonate() -> bool:
	if detonation_time == max_detonation_time:
		return true
	return false

func detonate() -> void: #special effects / other stuff here. starSystemAPI removes this body from starSystemAPi immediately after this
	pass
