extends Node
class_name colorOscillate

var active: Dictionary = {}
var current_time: float = 0.0

func oscillate_property(object: Object, property: NodePath, modulate1: Color, modulate2: Color, stop_step: int, oscillation_count: int, repeat: bool = false, over_step: bool = true) -> void:
	var colors: PackedColorArray = []
	for color in colorOscillateIterator.new(modulate1, modulate2, stop_step, oscillation_count, over_step):
		colors.append(color)
	var entry = Dictionary()
	entry["property"] = property.get_as_property_path()
	entry["steps"] = stop_step
	entry["repeat"] = repeat
	entry["modulate1"] = modulate1
	entry["colors"] = colors
	var schedule = active.get_or_add(object, Array())
	schedule.append(entry)
	pass

func clear_active() -> void:
	for object in active:
		var schedule = active.get(object)
		if schedule.size() > 0:
			var last_entry: Dictionary = schedule.back()
			
			var property = last_entry.get("property") as NodePath
			var modulate1 = last_entry.get("modulate1", Color.WHITE) as Color
			
			object.set_indexed(property, modulate1)
			
			schedule.clear()
	pass

func _process(delta: float) -> void:
	for object in active:
		var schedule = active.get(object)
		if schedule.size() > 0:
			var current_entry: Dictionary = schedule.front()
			var colors = current_entry.get("colors")
			current_time += delta
			
			var nearest_step: int = int(current_time)
			
			if nearest_step < current_entry.get("steps", 0):
				var nearest_color = colors.get(nearest_step) as Color
				var color: Color
				
				if colors.size() > (nearest_step + 1):
					var next_color = colors.get(nearest_step + 1) as Color
					var weight = current_time - nearest_step #should be between 0 and 1!
					color = nearest_color.lerp(next_color, weight)
				else:
					color = nearest_color
				
				var property = current_entry.get("property") as NodePath
				
				object.set_indexed(property, color)
				
			else:
				var repeat = current_entry.get("repeat", false) as bool
				
				if repeat:
					schedule.push_front(current_entry)
					schedule.remove_at(1)
				else:
					schedule.remove_at(0)
				
				current_time = 0.0
		else:
			active.erase(object)
	pass
