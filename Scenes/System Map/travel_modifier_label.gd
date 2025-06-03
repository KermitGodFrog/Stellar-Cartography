extends Label
#the idea here is this: when you are looking at a UI element about what your current action is, you MIGHT want to know what is affecting your ability to complete that action. therefore: travel modifiers

signal modifiersUpdated

var modifiers: Dictionary = {}
var displays: PackedStringArray = []
func separate_modifier_displays() -> void:
	displays.clear()
	for d in modifiers.values():
		displays.append(d)
	pass
func update() -> void:
	set_text(" & ".join(displays))
	pass



func _ready() -> void:
	connect("modifiersUpdated", _on_modifiers_updated)
	pass

func _on_modifiers_updated() -> void:
	separate_modifier_displays()
	update()
	pass



func add_modifier(id, display: String) -> void:
	modifiers[id] = display
	emit_signal("modifiersUpdated")
	pass

func remove_modifier(id) -> void:
	modifiers.erase(id)
	emit_signal("modifiersUpdated")
	pass

func check_modifier(id, display: String, add: bool) -> void:
	match add:
		true:
			add_modifier(id, display)
		false:
			remove_modifier(id)
	pass
