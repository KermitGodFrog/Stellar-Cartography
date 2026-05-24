extends HFlowContainer
#the idea here is this: when you are looking at a UI element about what your current action is, you MIGHT want to know what is affecting your ability to complete that action. therefore: travel modifiers
#^^^ this class is now used for both travel modifiers and status modifiers since they are just a lil bit similar !

@onready var indicator_scene = preload("uid://c080lw7341ugp")

signal modifiersUpdated

var modifiers: Dictionary = {}
var indicators: Dictionary = {}
func update() -> void:
	var invalid_indicators: Dictionary = indicators.duplicate()
	
	for id in modifiers:
		invalid_indicators.erase(id)
		if not indicators.has(id):
			add_indicator(id)
	
	for id in invalid_indicators:
		remove_indicator(id)
	pass



func _ready() -> void:
	connect("modifiersUpdated", _on_modifiers_updated)
	pass

func _on_modifiers_updated() -> void:
	update()
	pass



func add_modifier(id, title: String, description: String, effect: String) -> void:
	modifiers[id] = {"title": title, "description": description, "effect": effect}
	emit_signal("modifiersUpdated")
	pass

func remove_modifier(id) -> void:
	modifiers.erase(id)
	emit_signal("modifiersUpdated")
	pass

func check_modifier(id, title: String, description: String, effect: String, add: bool) -> void: #do NOT call this every frame !!! it should only be called when a variable is set to a new value
	match add:
		true:
			add_modifier(id, title, description, effect)
		false:
			remove_modifier(id)
	pass

func add_indicator(_associated_id) -> void:
	var instance = indicator_scene.instantiate()
	instance.associated_id = _associated_id
	instance.data = modifiers.get(_associated_id)
	indicators[_associated_id] = instance
	add_child(instance)
	pass

func remove_indicator(_associated_id) -> void:
	var instance = indicators.get(_associated_id, null)
	if instance != null:
		indicators.erase(_associated_id)
		instance.queue_free()
	pass
