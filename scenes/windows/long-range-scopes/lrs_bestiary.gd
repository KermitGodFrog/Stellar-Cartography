extends PanelContainer

var discovered_entities_matrix: PackedInt32Array = []:
	set(value):
		discovered_entities_matrix = value
		_on_discovered_entities_matrix_changed(value)

var current_entity : entityBodyAPI = null

@onready var tabs = $tabs
@onready var bestiary_list = $tabs/INDEX/bestiary_list
@onready var info_title = $tabs/INFO/info_title
@onready var info_description = $tabs/INFO/info_split/description_scroll/info_description
@onready var info_reward_widgets_list = $tabs/INFO/info_split/reward_widgets_panel/reward_widgets_scroll/reward_widgets_list

const ENTITY_CLASSIFICATION_DESCRIPTIONS = {
	game_data.ENTITY_CLASSIFICATIONS.SPACE_WHALE_POD: "Long-lasting, space-faring creatures which are usually observed in pods. Feast on space dust, asteroids, meteorites, and other sources of rare elements. Move via the expulsion of gasses out of the ‘tail’. These were the first extraterrestrial species observed by Humanity. First contact was initiated and recorded by a salvage ship - the recording consisted of salvage personnel in-the-yard gaping about ‘space whales’, with an extremely bewildered Command desperately asking for clarification. The straightforward term ‘space whales’ was soon picked up by news outlets documenting the discovery, and the name stuck despite scientific names being established.",
	game_data.ENTITY_CLASSIFICATIONS.LAGRANGE_CLOUD: "Space dust and asteroids situated in a stable, moving point of space wherein the gravitational pull of two nearby bodies cancels out. Such constructs tend to contain small ecosystems - usually characterised by the presence of species applicable to coral from Old Earth, which binds to asteroids and tends to be the most efficient form of life under the circumstances provided.",
	game_data.ENTITY_CLASSIFICATIONS.OLM_MAELSTROM: "Space-faring creatures which possess a remarkable resemblance to the early salamanders of Old Earth. Eat by absorbing sunlight through their 'gills' and move by manipulating space-time. The internal workings of this alien species inspired many of the improvements to starship propulsion in recent times."
}

const ENTITY_CLASSIFICATION_REWARD_WIDGETS = {
	game_data.ENTITY_CLASSIFICATIONS.SPACE_WHALE_POD: {"MEDIUM CLOSE-UP (200)": null, "SUBJECTS AT FOCAL POINT": null},
	game_data.ENTITY_CLASSIFICATIONS.LAGRANGE_CLOUD: {"LONG SHOT (70)": null, "SUBJECTS AROUND FOCAL POINT": null},
	game_data.ENTITY_CLASSIFICATIONS.OLM_MAELSTROM: {"EXTREME CLOSE-UP (750)": null, "SUBJECTS NEAR FOCAL POINT": null}
}

func _on_current_entity_changed(new_entity : entityBodyAPI):
	update_bestiary_list(discovered_entities_matrix)
	update_info(new_entity.entity_classification)
	tabs.set_current_tab(1) #info
	pass

func update_bestiary_list(_discovered_entities_matrix: PackedInt32Array = []):
	bestiary_list.clear()
	for classification in _discovered_entities_matrix:
		var new = bestiary_list.add_item(game_data.ENTITY_CLASSIFICATIONS.find_key(classification).capitalize())
		bestiary_list.set_item_metadata(new, classification)
	pass

func update_info(for_classification: game_data.ENTITY_CLASSIFICATIONS):
	info_reward_widgets_list.clear()
	info_title.set_text(game_data.ENTITY_CLASSIFICATIONS.find_key(for_classification).capitalize())
	info_description.set_text(ENTITY_CLASSIFICATION_DESCRIPTIONS.get(for_classification, ""))
	
	var widget_data_for_classification = ENTITY_CLASSIFICATION_REWARD_WIDGETS.get(for_classification)
	
	for widget in widget_data_for_classification:
		var widget_icon = widget_data_for_classification.get(widget)
		if widget_icon != null:
			info_reward_widgets_list.add_item(widget, widget_icon)
		else:
			info_reward_widgets_list.add_item(widget)
	pass

func _on_bestiary_list_item_activated(index):
	var classification = bestiary_list.get_item_metadata(index)
	update_info(classification)
	tabs.set_current_tab(1) #info
	pass

func _on_discovered_entities_matrix_changed(value):
	update_bestiary_list(value)
	pass
