extends PanelContainer

signal mutation_items_changed()

enum INIT_TYPES {DISPLAY, EDIT, DISPLAY_WITH_OFFSET} # copied from mutation_item.gd
enum LISTS {UNINSTALLED, INSTALLED} # copied from mutation_item.gd

@onready var uninstalled_list = $margin/scroll/UNINSTALLED/uninstalled_list
@onready var installed_list = $margin/scroll/INSTALLED/installed_list
@onready var points_counter = $margin/scroll/points_counter

@onready var mutation_item_scene = preload("uid://dte1ssronei0")

func _ready() -> void:
	uninstalled_list.connect("child_order_changed", _on_list_child_order_changed)
	installed_list.connect("child_order_changed", _on_list_child_order_changed)
	connect("mutation_items_changed", update_points_counter)
	var details_helper := game_data.loadUserDetails()
	for idx in details_helper.unlocked_mutations:
		add_mutation_item(idx, LISTS.UNINSTALLED)
	pass

func _on_list_child_order_changed() -> void:
	emit_signal("mutation_items_changed")
	pass

func update_points_counter() -> void:
	if points_counter != null:
		points_counter.set_text("CURRENT MUTATION POINTS: %d" % get_current_points())
	pass





func add_mutation_item(for_idx: worldAPI.MUTATION_ID, for_list: LISTS) -> void:
	var instance = mutation_item_scene.instantiate()
	instance.connect("ready", _on_mutation_item_ready.bind(instance, for_idx, for_list))
	instance.connect("activated", _on_mutation_item_activated)
	match for_list:
		LISTS.UNINSTALLED:
			uninstalled_list.add_child(instance)
		LISTS.INSTALLED:
			installed_list.add_child(instance)
	pass
func _on_mutation_item_ready(item: Node, idx: worldAPI.MUTATION_ID, list: LISTS) -> void:
	item.init_type = INIT_TYPES.EDIT
	item.current_list = list
	item.initialize(idx)
	pass

func remove_mutation_item(idx: worldAPI.MUTATION_ID, from_list: LISTS) -> void:
	match from_list:
		LISTS.UNINSTALLED:
			for item in get_uninstalled_mutation_items():
				if item.mutation == idx:
					item.queue_free()
		LISTS.INSTALLED:
			for item in get_installed_mutation_items():
				if item.mutation == idx:
					item.queue_free()
	pass

func _on_mutation_item_activated(idx: worldAPI.MUTATION_ID, list: LISTS) -> void:
	match list:
		LISTS.UNINSTALLED:
			remove_mutation_item(idx, list)
			add_mutation_item(idx, LISTS.INSTALLED)
		LISTS.INSTALLED:
			remove_mutation_item(idx, list)
			add_mutation_item(idx, LISTS.UNINSTALLED)
	pass






# misc

func get_uninstalled_mutation_items() -> Array[Node]:
	var items: Array[Node] = []
	for item in uninstalled_list.get_children():
		items.append(item)
	return items

func get_installed_mutation_items() -> Array[Node]:
	var items: Array[Node] = []
	for item in installed_list.get_children():
		items.append(item)
	return items

func get_installed_mutations() -> Array[worldAPI.MUTATION_ID]:
	var idx_array: Array[worldAPI.MUTATION_ID] = []
	for item in get_installed_mutation_items():
		idx_array.append(item.mutation)
	return idx_array

func get_current_points() -> int:
	var points: int = 0
	for item in get_installed_mutation_items():
		points += worldAPI.mutation_data.get(item.mutation).get("points_offset", 0)
	return points

func is_launch_valid() -> bool:
	if get_current_points() >= 0:
		return true
	else:
		return false

func get_init_data() -> Dictionary:
	var data: Dictionary = {}
	data["mutations"] = get_installed_mutations()
	return data
