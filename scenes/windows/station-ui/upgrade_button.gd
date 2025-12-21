extends Button
#needs to be in group 'FOLLOW_UPGRADE_STATE'

@export var upgrade: playerAPI.UPGRADE_ID
@export var cost: int
@export_multiline var description: String

func _ready():
	set_text("%s: %.fn" % [get_upgrade_name(), cost])
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == upgrade:
		match state:
			true:
				set_text("%s: UNLOCKED" % get_upgrade_name())
			false:
				set_text("%s: %.fn" % [get_upgrade_name(), cost])
	pass

func get_upgrade_name() -> String:
	return playerAPI.UPGRADE_ID.find_key(upgrade).to_upper().replace("_", " ")
