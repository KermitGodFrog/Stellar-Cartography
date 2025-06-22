extends PanelContainer
enum LISTS {HIERACHY, CHOICES}
enum ACTIONS {SWITCH_COLUMN, VIEW_IN_ENCYCLOPEDIA}

@onready var hierachy_list = $margin/tabs/REPORT/scroll/hierachy_texture/hierachy_margin/hierachy_list
@onready var choices_list = $margin/tabs/REPORT/scroll/choices_list

@onready var layer_representation = preload("res://Scenes/Gas Layer Surveyor/layer_representation.tscn")

var _layer_data: Dictionary = {}
#var current_layers: PackedStringArray = []

func initialize(_current_layers: PackedStringArray) -> void:
	#current_layers = _current_layers
	
	for c in choices_list.get_children(): c.queue_free()
	for c in hierachy_list.get_children(): c.queue_free()
	
	var converted_layers = Array(_current_layers)
	converted_layers.shuffle()
	
	for tag in converted_layers:
		add_layer_instance(tag, LISTS.CHOICES)
	pass



func add_layer_instance(tag: String, list: LISTS):
	var layer_instance = layer_representation.instantiate()
	layer_instance.connect("activated", _on_layer_instance_activated)
	layer_instance.initialize(tag, _layer_data.get(tag), list)
	match list:
		LISTS.CHOICES:
			choices_list.add_child(layer_instance)
		LISTS.HIERACHY:
			hierachy_list.add_child(layer_instance)
	pass

func remove_layer_instance(tag: String, list: LISTS):
	match list:
		LISTS.CHOICES:
			for c in choices_list.get_children():
				if c.tag == tag:
					c.queue_free()
		LISTS.HIERACHY:
			for c in hierachy_list.get_children():
				if c.tag == tag:
					c.queue_free()
	pass

func _on_layer_instance_activated(tag: String, list: LISTS, action: ACTIONS):
	match action:
		ACTIONS.SWITCH_COLUMN:
			match list:
				LISTS.CHOICES:
					remove_layer_instance(tag, list)
					add_layer_instance(tag, LISTS.HIERACHY)
				LISTS.HIERACHY:
					remove_layer_instance(tag, list)
					add_layer_instance(tag, LISTS.CHOICES)
		ACTIONS.VIEW_IN_ENCYCLOPEDIA:
			pass
	pass
