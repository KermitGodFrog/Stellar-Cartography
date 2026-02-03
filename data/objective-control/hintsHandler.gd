extends Node
#uses eventsHandler info to send 'hint' messages to system_map console

signal addHint(message: String)

var hints_enabled: bool = true
var used_hint_wIDs: Array[String]

func process_campaign_event(calling: Node, incoming_wID: String, incoming_value: Variant = null) -> void:
	if hints_enabled:
		if not incoming_wID in used_hint_wIDs:
			used_hint_wIDs.append(incoming_wID)
			
	pass
