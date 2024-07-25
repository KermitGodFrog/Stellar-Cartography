extends Resource
class_name playerAPI

var position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var slowdown: bool = true
var current_star_system: starSystemAPI
var previous_star_system: starSystemAPI

var speed: int = 1
var balance: int = 0
var current_value: int = 0

var max_jumps: int = 5
var jumps_remaining: int = 0

enum UPGRADE_ID {ADVANCED_SCANNING, AUDIO_VISUALIZER}
var unlocked_upgrades: Array[UPGRADE_ID] = []

var saved_audio_profiles: Array[audioProfileHelper] = []
var max_saved_audio_profiles: int = 10

var characters: Array[characterAPI] = []


func get_jumps_remaining():
	return jumps_remaining

func get_max_jumps():
	return max_jumps

func set_max_jumps(value: int):
	max_jumps = value
	pass


func updatePosition(delta):
	match slowdown:
		true:
			if not position.distance_to(target_position) < speed:
				position += position.direction_to(target_position) * speed * delta
			else:
				position += position.direction_to(target_position) * position.distance_to(target_position) * delta
		false:
			if not position.distance_to(target_position) < (speed * delta):
				position += position.direction_to(target_position) * speed * delta
			else:
				position = target_position
	pass

func setTargetPosition(pos: Vector2):
	target_position = pos
	pass


func resetJumpsRemaining():
	jumps_remaining = max_jumps
	pass

func removeJumpsRemaining(amount: int):
	jumps_remaining = maxi(0, jumps_remaining - amount)
	pass

func addJumpsRemaining(amount: int):
	jumps_remaining = mini(max_jumps, jumps_remaining + amount)
	pass


func unlockUpgrade(upgrade_idx: UPGRADE_ID):
	if not unlocked_upgrades.has(upgrade_idx):
		unlocked_upgrades.append(upgrade_idx)
		return upgrade_idx
	return -1

func lockUpgrade(upgrade_idx: UPGRADE_ID):
	if unlocked_upgrades.has(upgrade_idx):
		unlocked_upgrades.erase(upgrade_idx)
		return upgrade_idx
	return -1

func get_unlocked_upgrades():
	return unlocked_upgrades

func get_upgrade_unlocked_state(upgrade_idx: UPGRADE_ID):
	if unlocked_upgrades.has(upgrade_idx):
		return true
	else:
		return false


func increaseBalance(amount: int):
	balance += amount
	pass

func decreaseBalance(amount: int):
	balance = maxi(0, balance - amount)
	pass


func addAudioProfile(helper: audioProfileHelper):
	#gotta check for whether adding the profile will still keep the array under the max size integer!!!!!
	if saved_audio_profiles.size() < max_saved_audio_profiles:
		saved_audio_profiles.append(helper)
		return saved_audio_profiles.find(helper)
	return -1

func removeAudioProfile(helper: audioProfileHelper):
	if saved_audio_profiles.has(helper):
		saved_audio_profiles.erase(helper)
	pass
