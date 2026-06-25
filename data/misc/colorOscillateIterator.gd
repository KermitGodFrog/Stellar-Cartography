extends Resource
class_name colorOscillateIterator

var _modulate1: Color
var _modulate2: Color
var _stop_step: int
var _oscillation_count: int
var _over_step: bool

func _init(modulate1: Color, modulate2: Color, stop_step: int, oscillation_count: int, over_step: bool = true) -> void:
	_modulate1 = modulate1
	_modulate2 = modulate2
	_stop_step = stop_step
	_oscillation_count = oscillation_count
	_over_step = over_step
	pass

func _should_continue(current_step) -> bool:
	if _over_step:
		return current_step < (_stop_step + 1) # +1 so it wraps neatly
	else:
		return current_step < _stop_step

func _iter_init(iter: Array) -> bool:
	#print("ITER_INIT: ", iter)
	iter[0] = [_modulate1, 0]
	return _should_continue(iter[0][1])

func _iter_next(iter: Array) -> bool:
	#print("ITER NEXT: ", iter)
	iter[0][1] += 1
	iter[0][0] = _modulate1.lerp(_modulate2, pingpong(sin(remap(iter[0][1], 0, _stop_step, 0.0, PI * _oscillation_count)), 1.0))
	return _should_continue(iter[0][1])

func _iter_get(arg):
	#print("ITER GET: ", arg)
	return arg[0]
