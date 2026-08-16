extends "res://scenes/system-map/custom_tooltip_button.gd"
#needs to be in group 'FOLLOW_UPGRADE_STATE'

var _refund_upgrade_price_multiplier: float = 0.0

var upgrade: playerAPI.UPGRADE_ID
var cost: int
var description: String
var effect: String
var unlocked: bool = false

func _ready():
	set_text("%s: %.fn" % [get_upgrade_name(upgrade), cost])
	tooltip_title = get_upgrade_name(upgrade)
	
	var combined_tooltip: String = String()
	var incomp_text: String = String()
	var req_text: String = String()
	
	for u in playerAPI.upgrade_incompatibilities.get(upgrade, []):
		incomp_text += "* %s\n" % get_upgrade_name(u)
	for u in playerAPI.upgrade_requirements.get(upgrade, []):
		req_text += "* %s\n" % get_upgrade_name(u)
	
	combined_tooltip += "[i]%s[/i]" % description
	combined_tooltip += "\n\n[color=lightyellow]Effect:[/color]\n%s" % effect
	if incomp_text.length() > 0 or req_text.length() > 0:
		combined_tooltip += "\n\n[color=yellow][table=2] \
		[cell]Incompatible w/:[/cell][cell]Requires:[/cell] \
		[cell]%s[/cell][cell]%s[/cell][/table][/color]" % [incomp_text, req_text]
	
	tooltip_text = combined_tooltip
	
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	pass

func _on_mouse_entered() -> void:
	if unlocked:
		set_text("%s: SELL %.fn" % [get_upgrade_name(upgrade), cost * _refund_upgrade_price_multiplier]) #assumes sell_module_price_multiplier is 0.25 - replicate real value from station_ui please
	pass

func _on_mouse_exited() -> void:
	if unlocked:
		set_text("%s: UNLOCKED" % get_upgrade_name(upgrade))
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == upgrade:
		unlocked = state
		match state:
			true:
				set_text("%s: UNLOCKED" % get_upgrade_name(upgrade))
			false:
				set_text("%s: %.fn" % [get_upgrade_name(upgrade), cost])
	pass

func get_upgrade_name(u: playerAPI.UPGRADE_ID) -> String:
	return playerAPI.UPGRADE_ID.find_key(u).to_upper().replace("_", " ")
