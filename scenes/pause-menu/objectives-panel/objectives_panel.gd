extends PanelContainer

var item_anchor: Node
var scroll_container: Node

@onready var objective_item = preload("uid://c4inc2m5l36fl")
@onready var _confirm_texture = preload("uid://c5r5ok7jmth3o")
@onready var _denied_texture = preload("uid://cudxvqxk513ea")

var active_objectives: Array[objectiveAPI] = []

func _ready() -> void:
	item_anchor = $margin/scroll_container/item_anchor
	scroll_container = $margin/scroll_container
	pass

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
	
	scroll_container.set_v_scroll(int())
	pass
