extends Label
#the idea here is this: when you are looking at a UI element about what your current action is, you MIGHT want to know what is affecting your ability to complete that action. therefore: travel modifiers

var modifiers: Dictionary = {}
var last_modifiers: Dictionary = {}
var displays: PackedStringArray = []

func separate_modifier_displays() -> void:
	displays.clear()
	for d in modifiers.values():
		displays.append(d)
	pass

func update() -> void:
	set_text(" + ".join(displays))
	pass


func _physics_process(delta: float) -> void:
	#couldnt find a way to not make this run every frame because i am very FUCKING TIRED right now so the performance issue in my mind DOES NOT MATTER (at the moment) HAHAHAHAHAHAHAHAHAHAH
	separate_modifier_displays()
	update()
	pass


func add_modifier(id, display: String) -> void:
	modifiers[id] = display
	pass

func remove_modifier(id) -> void:
	modifiers.erase(id)
	pass

func check_modifier(id, display: String, add: bool) -> void:
	match add:
		true:
			add_modifier(id, display)
		false:
			remove_modifier(id)
	pass
