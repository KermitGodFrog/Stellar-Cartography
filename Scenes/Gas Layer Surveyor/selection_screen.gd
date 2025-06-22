extends PanelContainer
enum LISTS {HIERACHY, CHOICES}
enum ACTIONS {SWITCH_COLUMN, VIEW_IN_ENCYCLOPEDIA}

var discovered_gas_layers_matrix: PackedInt32Array = []

@onready var hierachy_list = $margin/tabs/REPORT/scroll/hierachy_texture/hierachy_margin/hierachy_list
@onready var choices_list = $margin/tabs/REPORT/scroll/choices_list
@onready var encyclopedia = $margin/tabs/ENCYCLOPEDIA
@onready var tabs = $margin/tabs
#ENTRY tab
@onready var tag_label = $margin/tabs/ENTRY/tag_label
@onready var noise_texture = $margin/tabs/ENTRY/noise_texture
@onready var attributes_list = $margin/tabs/ENTRY/attributes_list 


@onready var layer_representation = preload("res://Scenes/Gas Layer Surveyor/layer_representation.tscn")

var _layer_data: Dictionary = {}

func _ready() -> void:
	tabs.set_tab_hidden(2, true)
	pass


func initialize(_current_layers: PackedStringArray) -> void:
	#clear and populate REPORT
	for c in choices_list.get_children(): c.queue_free()
	for c in hierachy_list.get_children(): c.queue_free()
	
	var converted_layers = Array(_current_layers)
	converted_layers.shuffle()
	
	for tag in converted_layers:
		add_layer_instance(tag, LISTS.CHOICES)
	
	#clear and populate ENCYCLOPEDIA
	encyclopedia.clear()
	for idx in discovered_gas_layers_matrix:
		var tag = _layer_data.keys()[idx]
		var new = encyclopedia.add_item(tag.to_upper())
		encyclopedia.set_item_metadata(new, tag)
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
			switch_to_entry(tag)
	pass





func _on_encyclopedia_item_selected(index: int) -> void:
	var tag = encyclopedia.get_item_metadata(index)
	switch_to_entry(tag)
	pass 

func switch_to_entry(tag: String) -> void:
	var data = _layer_data.get(tag)
	tag_label.set_text(tag.to_upper())
	noise_texture.set_texture(data.get("bg_sampler", load("res://Scenes/Gas Layer Surveyor/bg_default.tres")))
	attributes_list.clear()
	
	var current_idx: int = 0
	
	attributes_list.add_item("SPEED")
	attributes_list.add_item("%.f" % remap(data.get("bg_time_divisor", 100.0), 0, 250, 250, 0))
	
	attributes_list.add_item("COLOR")
	current_idx = attributes_list.add_item(String())
	attributes_list.set_item_custom_bg_color(current_idx, data.get("bg_color", Color.WHITE))
	
	attributes_list.add_item("ALBEDO")
	current_idx = attributes_list.add_item(String())
	attributes_list.set_item_custom_bg_color(current_idx, data.get("fog_albedo", Color.WHITE))
	
	attributes_list.add_item("EMISSION")
	current_idx = attributes_list.add_item(String())
	attributes_list.set_item_custom_bg_color(current_idx, data.get("fog_emission", Color.BLACK))
	
	tabs.set_current_tab(2)
	pass
