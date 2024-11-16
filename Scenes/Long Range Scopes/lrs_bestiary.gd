extends PanelContainer

var discovered_entities_matrix: PackedInt32Array = []
var current_entity : entityAPI = null

@onready var tabs = $tabs

var entity_descriptions = {
	game_data.ENTITY_CLASSIFICATIONS.SPACE_WHALE_POD: "Long-lasting, space-faring creatures which are usually observed in pods. Feast on space dust, asteroids, meteorites, and other sources of rare elements. Move via the expulsion of gasses out of the ‘tail’. These were the first extraterrestrial species observed by Humanity. First contact was initiated and recorded by a salvage ship - the recording consisted of salvage personnel in-the-yard gaping about ‘space whales’, with an extremely bewildered command continuously asking them to ‘restate their previous’. The straightforward term ‘space whales’ was soon picked up by news outlets documenting the discovery, and the name stuck despite scientific names being established."
}


func _on_current_entity_changed(new_entity : entityAPI):
	update_bestiary_list()
	update_info(new_entity.entity_classification)
	tabs.set_current_tab(1)
	pass

func update_bestiary_list():
	
	
	
	pass

func update_info(for_entity_classification: game_data.ENTITY_CLASSIFICATIONS):
	pass
