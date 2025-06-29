extends Node
#used mostly to trigger objectives. just takes in a whole lot of updates which would be too expensive/too often to pass through dialogueManager and responds to em
#game.gd not allowed to use speak()

var init_type: int #FROM GLOBAL DATA INIT TYPES

func speak(_calling: Node, _incoming_wID: String, _incoming_value: Variant = null) -> void:
	match init_type:
		global_data.GAME_INIT_TYPES.TUTORIAL:
			process_tutorial_event(_calling, _incoming_wID, _incoming_value)
		_:
			process_campaign_event(_calling, _incoming_wID, _incoming_value)
	pass

func process_tutorial_event(calling: Node, incoming_wID: String, incoming_value: Variant = null) -> void:
	pass

func process_campaign_event(calling: Node, incoming_wID: String, incoming_value: Variant = null) -> void:
	pass
