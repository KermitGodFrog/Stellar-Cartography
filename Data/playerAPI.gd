extends Resource
class_name playerAPI

signal orbitingBody(body: bodyAPI)
signal followingBody(body: bodyAPI)

var position: Vector2 = Vector2.ZERO
var current_star_system: starSystemAPI
var previous_star_system: starSystemAPI

var speed: int = 1
var balance: int = 0
var current_value: int = 0

var max_jumps: int = 5
var jumps_remaining: int = 0
var systems_traversed: int = 0
var weirdness_index :
	get:
		return remap(systems_traversed, 0, 35, 0.0, 1.0)

enum UPGRADE_ID {ADVANCED_SCANNING, AUDIO_VISUALIZER}
var unlocked_upgrades: Array[UPGRADE_ID] = []

var saved_audio_profiles: Array[audioProfileHelper] = []
var max_saved_audio_profiles: int = 10

#characters \/\/\/\/\/\/
var first_officer: characterAPI
var chief_engineer: characterAPI
var security_officer: characterAPI
var medical_officer: characterAPI
var linguist: characterAPI
var historian: characterAPI

#stuff ported from old system_map.gd - no idea how it works so dont ask me hahahahhaah good luck
var rotation_hint: float #used for orbiting mechanics
var target_position: Vector2 = Vector2.ZERO
enum ACTION_TYPES {NONE, GO_TO, ORBIT}
var current_action_type: ACTION_TYPES = ACTION_TYPES.NONE
var pending_action_body : bodyAPI
var action_body : bodyAPI

func get_jumps_remaining():
	return jumps_remaining

func get_max_jumps():
	return max_jumps

func set_max_jumps(value: int):
	max_jumps = value
	pass


func updatePosition(delta): #dont ask bro
	rotation_hint += delta
	if pending_action_body:
		match current_action_type:
			ACTION_TYPES.NONE:
				if not position.distance_to(target_position) < speed:
					position += position.direction_to(target_position) * speed * delta
				else:
					position += position.direction_to(target_position) * position.distance_to(target_position) * delta
			ACTION_TYPES.GO_TO:
				var pos = pending_action_body.position
				if not position.distance_to(pos) < (pending_action_body.radius):
					position += position.direction_to(pos) * speed * delta
				else:
					position = pos
				target_position = pos #not actually used for moving, just for drawing where the player is moving to
			ACTION_TYPES.ORBIT:
				var dir = Vector2.UP.rotated(rotation_hint)
				var pos = pending_action_body.position
				pos = pos + (dir * ((3 * pending_action_body.radius) + 1.0))
				if not position.distance_to(pos) < (pending_action_body.radius):
					position += position.direction_to(pos) * speed * delta
				else:
					position = pos
				target_position = pos #not actually used for moving, just for drawing where the player is moving to
	elif action_body:
		match current_action_type:
			ACTION_TYPES.NONE:
				if not position.distance_to(target_position) < speed:
					position += position.direction_to(target_position) * speed * delta
				else:
					position += position.direction_to(target_position) * position.distance_to(target_position) * delta
			ACTION_TYPES.GO_TO:
				var pos = action_body.position
				position = pos
				target_position = pos #not actually used for moving, just for drawing where the player is moving to
			ACTION_TYPES.ORBIT:
				var dir = Vector2.UP.rotated(rotation_hint)
				var pos = action_body.position
				pos = pos + (dir * ((3 * action_body.radius) + 1.0))
				position = pos
				target_position = pos #not actually used for moving, just for drawing where the player is moving to
	if (not pending_action_body) and (not action_body):
		if not position.distance_to(target_position) < speed:
			position += position.direction_to(target_position) * speed * delta
		else:
			position += position.direction_to(target_position) * position.distance_to(target_position) * delta
	pass

func setTargetPosition(pos: Vector2):
	target_position = pos
	pass

func updateActionBodyState():
	if pending_action_body:
		match current_action_type:
			ACTION_TYPES.NONE:
				pending_action_body = null
				action_body = null
			ACTION_TYPES.GO_TO:
				var pos = pending_action_body.position
				if position.distance_to(pos) < (pending_action_body.radius + 1.0):
					emit_signal("followingBody", pending_action_body)
					action_body = pending_action_body
					pending_action_body = null
			ACTION_TYPES.ORBIT:
				var dir = Vector2.UP.rotated(rotation_hint)
				var pos = pending_action_body.position
				pos = pos + (dir * ((3 * pending_action_body.radius) + 1.0))
				if position.distance_to(pos) < (pending_action_body.radius + 1.0):
					emit_signal("orbitingBody", pending_action_body)
					action_body = pending_action_body
					pending_action_body = null
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
