extends Button
#needs to be in group 'FOLLOW_UPGRADE_STATE'

var _refund_upgrade_price_multiplier: float = 0.0

@export var upgrade: playerAPI.UPGRADE_ID
@export var cost: int
@export_multiline var description: String
@export var unlocked: bool = false

func _ready():
	set_text("%s: %.fn" % [get_upgrade_name(), cost])
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	pass

func _on_mouse_entered() -> void:
	if unlocked:
		set_text("%s: SELL %.fn" % [get_upgrade_name(), cost * _refund_upgrade_price_multiplier]) #assumes sell_module_price_multiplier is 0.25 - replicate real value from station_ui please
	pass

func _on_mouse_exited() -> void:
	if unlocked:
		set_text("%s: UNLOCKED" % get_upgrade_name())
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == upgrade:
		unlocked = state
		match state:
			true:
				set_text("%s: UNLOCKED" % get_upgrade_name())
			false:
				set_text("%s: %.fn" % [get_upgrade_name(), cost])
	pass

func get_upgrade_name() -> String:
	return playerAPI.UPGRADE_ID.find_key(upgrade).to_upper().replace("_", " ")
