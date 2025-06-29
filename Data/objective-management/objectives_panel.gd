extends PanelContainer

@onready var item_anchor = $margin/scroll_container/item_anchor

@onready var objective_item = preload("res://Data/objective-management/objective_item.tscn")
@onready var _confirm_texture = preload("res://Graphics/Misc/confirm_no_shadow.png")
@onready var _denied_texture = preload("res://Graphics/Misc/denied.png")

var active_objectives: Array[objectiveAPI] = []

func _on_update_objectives_panel(_active_objectives: Array[objectiveAPI]) -> void: #{file name: objectiveAPI}
	active_objectives = _active_objectives
	generate()
	pass

func generate():
	var children = item_anchor.get_children()
	for child in children:
		child.queue_free()
	for o in active_objectives:
		var instance = objective_item.instantiate()
		item_anchor.add_child(instance)
		instance.confirm_texture = _confirm_texture
		instance.denied_texture = _denied_texture
		instance.initialize(o.title, o.description, o.get_state())
	pass
