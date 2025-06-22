extends PanelContainer

@onready var hierachy_list = $margin/tabs/REPORT/scroll/hierachy_texture/hierachy_margin/hierachy_list
@onready var choices_list = $margin/tabs/REPORT/scroll/choices_list

@onready var layer_representation = preload("res://Scenes/Gas Layer Surveyor/layer_representation.tscn")

var _layer_data: Dictionary = {}
#var current_layers: PackedStringArray = []

func initialize(_current_layers: PackedStringArray) -> void:
	#current_layers = _current_layers
	
	for c in choices_list.get_children(): c.queue_free()
	for c in hierachy_list.get_children(): c.queue_free()
	
	for layer in _current_layers:
		var layer_instance = layer_representation.instantiate()
		layer_instance.initialize(layer, _layer_data.get(layer))
		choices_list.add_child(layer_instance)
		
		
	
	
	
	
	
	
	pass
