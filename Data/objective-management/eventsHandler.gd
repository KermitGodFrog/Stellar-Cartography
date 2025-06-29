extends Node
#used mostly to trigger objectives. just takes in a whole lot of updates which would be too expensive/too often to pass through dialogueManager and responds to em
#game.gd not allowed to use speak() <<<<<< IMPORTANT !!!!
#incoming_wIDs must be in the present tense >>>> [name][state]
#must be called with flags and subsequently UNIQUE and DEFERRED
#cannot be called every frame nontheless

signal markObjective(_wID: String, _state: objectiveAPI.STATES)

#REGISTERED FOR CAMPAIGN:
#AV_picker_select
#GLS_state_selecting
#LRS_display_photo

#REGISTERED FOR TUTORIAL:
#player_boosting_start
#player_target_position_update
#help_overlay_show
#system_list_info_tab_select
#journey_map_open
#system_map_camera_move
#scopes_fov_change

var init_type: int #FROM GLOBAL DATA INIT TYPES

func speak(_calling: Node, _incoming_wID: String, _incoming_value: Variant = null) -> void:
	#print("EVENTS HANDLER: ", _calling, " EVENT ", _incoming_wID)
	match init_type:
		global_data.GAME_INIT_TYPES.TUTORIAL:
			process_tutorial_event(_calling, _incoming_wID, _incoming_value)
		_:
			process_campaign_event(_calling, _incoming_wID, _incoming_value)
	pass

func process_tutorial_event(_calling: Node, incoming_wID: String, _incoming_value: Variant = null) -> void:
	match incoming_wID:
		"help_overlay_show":
			emit_signal("markObjective", "tutorialOptionalHelpOverlay", objectiveAPI.STATES.SUCCESS)
		"system_map_camera_move":
			emit_signal("markObjective", "tutorialOptionalTestSystemMap", objectiveAPI.STATES.SUCCESS)
		"scopes_fov_change":
			emit_signal("markObjective", "tutorialOptionalZoomScopes", objectiveAPI.STATES.SUCCESS)
		"player_target_position_update":
			emit_signal("markObjective", "tutorialOptionalManualControl", objectiveAPI.STATES.SUCCESS)
		"player_boosting_start":
			emit_signal("markObjective", "tutorialOptionalBoost", objectiveAPI.STATES.SUCCESS)
		"journey_map_open":
			emit_signal("markObjective", "tutorialOptionalJourneyMap", objectiveAPI.STATES.SUCCESS)
		"system_list_info_tab_select":
			emit_signal("markObjective", "tutorialOptionalInfo", objectiveAPI.STATES.SUCCESS)
	pass

func process_campaign_event(_calling: Node, _incoming_wID: String, _incoming_value: Variant = null) -> void:
	pass
