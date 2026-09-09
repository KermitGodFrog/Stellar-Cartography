extends PanelContainer

@onready var mutations_boundary = $margin/scroll/mutations_boundary
@onready var mutations_scroll = $margin/scroll/mutations_boundary/mutations_scroll

var installed_mutations: Array[worldAPI.MUTATION_ID] = []

@onready var mutation_item_scene = preload("uid://dte1ssronei0")

func regenerate() -> void:
	var f_installed_mutations: Array[worldAPI.MUTATION_ID] = installed_mutations.duplicate()
	f_installed_mutations.erase(worldAPI.MUTATION_ID.BASE)
	
	for item in mutations_scroll.get_children():
		item.queue_free()
	
	var current_time: float = 0.0
	for idx in f_installed_mutations:
		var item := global_data.get_mutation_item(idx, _on_mutation_item_ready)
		mutations_scroll.add_child(item)
		get_tree().create_timer(current_time + 0.15).timeout.connect(_on_mutation_item_popup.bind(item))
		current_time += 0.15
	pass

func _on_mutation_item_ready(item: Node, idx: worldAPI.MUTATION_ID) -> void:
	item.init_type = item.INIT_TYPES.DISPLAY_WITH_OFFSET
	item.initialize(idx)
	pass
func _on_mutation_item_popup(item: Node) -> void:
	item.popup()
	item.grab_focus()
	pass
