extends "res://scenes/pause-menu/objectives-panel/objectives_panel.gd"

@onready var misc_item_anchor = $scroll/margin/split_container/misc_scroll_container/misc_item_anchor
@onready var misc_scroll_container = $scroll/margin/split_container/misc_scroll_container

func _ready() -> void:
	item_anchor = $scroll/margin/split_container/scroll_container/item_anchor
	scroll_container = $scroll/margin/split_container/scroll_container
	pass

func generate():
	var children = item_anchor.get_children()
	children.append_array(misc_item_anchor.get_children())
	for child in children:
		child.queue_free()
	for o in active_objectives:
		var instance = objective_item.instantiate()
		match o.get_state():
			objectiveAPI.STATES.NONE:
				item_anchor.add_child(instance)
			_:
				misc_item_anchor.add_child(instance)
		instance.confirm_texture = _confirm_texture
		instance.denied_texture = _denied_texture
		instance.initialize(o.title, o.description, o.get_state())
	
	scroll_container.set_v_scroll(int())
	misc_scroll_container.set_v_scroll(int())
	pass
