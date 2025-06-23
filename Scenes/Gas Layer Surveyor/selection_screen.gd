extends PanelContainer
enum LISTS {HIERACHY, CHOICES}
enum ACTIONS {SWITCH_COLUMN, VIEW_IN_ENCYCLOPEDIA}
enum STATUSES {NONE, CONFIRMED, DENIED}

enum STATES {WAITING, SURVEYING, SELECTING, INVALID}

signal addPlayerValue(amount: int)
signal confirmedTwice()

var discovered_gas_layers_matrix: PackedInt32Array = []
var current_planet_value: int = 0

@onready var hierachy_list = $margin/tabs/REPORT/scroll/hierachy_texture/hierachy_margin/hierachy_list
@onready var choices_list = $margin/tabs/REPORT/scroll/choices_list
@onready var encyclopedia = $margin/tabs/ENCYCLOPEDIA
@onready var tabs = $margin/tabs
@onready var confirm_button = $margin/tabs/REPORT/confirm
#ENTRY tab
@onready var tag_label = $margin/tabs/ENTRY/tag_label
@onready var noise_texture = $margin/tabs/ENTRY/noise_texture
@onready var attributes_list = $margin/tabs/ENTRY/attributes_list 

@onready var layer_representation = preload("res://Scenes/Gas Layer Surveyor/layer_representation.tscn")

var _layer_data: Dictionary = {} # set on game start
var _current_layers: PackedStringArray = []
var confirmed_prev: bool = false:
	set(value):
		confirmed_prev = value
		confirm_button.oscillate = value

func _ready() -> void:
	tabs.set_tab_hidden(2, true)
	pass

func initialize(current_layers: PackedStringArray) -> void:
	#clearing and resetting misc
	_current_layers = current_layers
	confirmed_prev = false
	
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



#REPORT
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



#ENCYCLOPEDIA
func _on_encyclopedia_item_activated(index: int) -> void:
	var tag = encyclopedia.get_item_metadata(index)
	switch_to_entry(tag)
	pass 

func switch_to_entry(tag: String) -> void:
	var data = _layer_data.get(tag)
	tag_label.set_text(tag.to_upper())
	noise_texture.set_texture(data.get("bg_sampler", load("res://Scenes/Gas Layer Surveyor/bg_default.tres")))
	attributes_list.clear()
	
	attributes_list.add_item("TIME")
	attributes_list.add_item("%.f" % data.get("bg_time_divisor", 100.0))
	
	var color_properties: Dictionary = {"bg_color": Color.WHITE, "fog_albedo": Color.WHITE, "fog_emission": Color.BLACK}
	for property in color_properties:
		var color = data.get(property, color_properties.get(property))
		var text: String = String()
		match property:
			"bg_color": text = "COLOR"
			"fog_albedo": text = "ALBEDO"
			"fog_emission": text = "EMISSION"
		attributes_list.add_item(text)
		var idx = attributes_list.add_item(color.to_html())
		attributes_list.set_item_custom_bg_color(idx, color)
		attributes_list.set_item_custom_fg_color(idx, color.inverted())
	
	tabs.set_current_tab(2)
	pass



#FINISHING THE HECKING MINIGAME
func _on_confirm_pressed() -> void:
	if not confirmed_prev:
		var total: int = 0
		var average_value = int(current_planet_value / 9)
		
		var hierachy_children = hierachy_list.get_children()
		if _current_layers.size() == hierachy_children.size():
			confirmed_prev = true
			
			for idx in _current_layers.size():
				var confirmed_tag = _current_layers[idx]
				var child = hierachy_children[idx]
				if confirmed_tag == child.tag:
					var real_value = maxi(0, randfn(average_value, 50))
					total += real_value
					child.set_status(STATUSES.CONFIRMED, real_value)
				else:
					child.set_status(STATUSES.DENIED)
			emit_signal("addPlayerValue", total)
		else:
			confirm_button.blink(Color.RED)
	else:
		emit_signal("confirmedTwice")
	pass
