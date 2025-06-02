extends Resource
class_name playerAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

signal orbitingBody(body: bodyAPI)
signal followingBody(body: bodyAPI)
signal hullDeteriorationChanged(new_value: int)
signal moraleChanged(new_value: int)
signal dataValueChanged(new_value: int)
signal actionTypePendingOrCompleted(_type: ACTION_TYPES, _body: bodyAPI, _pending: bool) #unlike the system_map.gd updatePlayerActionType signal, this one includes whether the action type is pending or not, e.g. it updates again once the action is achieved

@export var name: String
@export var prefix: String

@export_storage var position: Vector2 = Vector2.ZERO
@export_storage var current_star_system: starSystemAPI
@export_storage var previous_star_system: starSystemAPI

@export var speed: int = 3 :
	get:
		if boosting:
			return speed * 5 * (1 + (-int(in_asteroid_belt) * 0.5))
		else:
			return speed * (1 + (-int(in_asteroid_belt) * 0.5))
var boosting: bool = false
var in_asteroid_belt: bool = false

@export var balance: int = 0
@export var current_value: int = 0:
	set(value):
		current_value = value
		#print_debug("PLAYER DATA VALUE CHANGED: ", current_value)
		emit_signal("dataValueChanged", current_value)
@export var net_worth: int = 0
var total_score: int = 0:
	get:
		return (net_worth + current_value) * systems_traversed

#key customization stufufffuff
@export var total_systems: int 
@export var max_jumps: int
@export var hull_stress_wormhole: int
@export var hull_stress_CME: int

@export_storage var jumps_remaining: int = 0
@export_storage var systems_traversed: int = 0
var weirdness_index :
	get:
		return remap(systems_traversed, 0, total_systems, 0.0, 1.0)

enum STORYLINES {THE_DETECTIVE, THE_CONGLOMERATE}
@export var current_storyline: STORYLINES

@export_storage var hull_deterioration: int = 0
@export_storage var hull_stress: int = 0
@export_storage var morale: int = 95
#@export_storage var mutiny_backing: int = 0

enum UPGRADE_ID {ADVANCED_SCANNING, AUDIO_VISUALIZER, NANITE_CONTROLLER, LONG_RANGE_SCOPES, SCAN_PREDICTION}
@export var unlocked_upgrades: Array[UPGRADE_ID] = []

@export var saved_audio_profiles: Array[audioProfileHelper] = []
@export var max_saved_audio_profiles: int = 10

@export var discovered_entities: PackedInt32Array = [] #int enum identifier from game.gd, e.g - [0,5,9]

@export_storage var CME_immune: bool = false #didnt know where to put this

@export var characters: Array[characterAPI] = [
	preload("res://Data/Characters/rui.tres"),
	preload("res://Data/Characters/jiya.tres"),
	preload("res://Data/Characters/walker.tres"),
	preload("res://Data/Characters/febris.tres")
	]
func get_character_with_occupation(occupation: characterAPI.OCCUPATIONS) -> characterAPI:
	for c in characters:
		if c.get_occupation() == occupation:
			return c
	return null

#stuff ported from old system_map.gd - no idea how it works so dont ask me hahahahhaah good luck
var rotation_hint: float #used for orbiting mechanics
@export_storage var target_position: Vector2 = Vector2.ZERO
enum ACTION_TYPES {NONE, GO_TO, ORBIT}
@export_storage var current_action_type: ACTION_TYPES = ACTION_TYPES.NONE
@export_storage var pending_action_body : bodyAPI:
	set(value):
		pending_action_body = value
		emit_signal("actionTypePendingOrCompleted", current_action_type, pending_action_body, true)
@export_storage var action_body : bodyAPI:
	set(value):
		action_body = value
		emit_signal("actionTypePendingOrCompleted", current_action_type, action_body, false)

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
	else:
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
					var temp = pending_action_body #ugly but necessary for current action display to work (temp)
					pending_action_body = null
					action_body = temp
			ACTION_TYPES.ORBIT:
				var dir = Vector2.UP.rotated(rotation_hint)
				var pos = pending_action_body.position
				pos = pos + (dir * ((3 * pending_action_body.radius) + 1.0))
				if position.distance_to(pos) < (pending_action_body.radius + 1.0):
					emit_signal("orbitingBody", pending_action_body)
					var temp = pending_action_body #ugly but necessary for current action display to work (temp)
					pending_action_body = null
					action_body = temp
	elif action_body: #ugly but necessary for current action display to work - i still have no ufcking idea what is going on here DO NOT TOUCH IT 
		match current_action_type:
			ACTION_TYPES.NONE:
				pending_action_body = null
				action_body = null
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
	net_worth += amount
	pass

func decreaseBalance(amount: int):
	balance = maxi(0, balance - amount)
	pass


func addAudioProfile(helper: audioProfileHelper):
	if saved_audio_profiles.size() < max_saved_audio_profiles:
		saved_audio_profiles.append(helper)
		return saved_audio_profiles.find(helper)
	return -1

func removeAudioProfile(helper: audioProfileHelper):
	if saved_audio_profiles.has(helper):
		saved_audio_profiles.erase(helper)
	pass


func addHullStress(amount: int) -> void:
	var adjusted = hull_stress + amount
	if adjusted > 100:
		addHullDeterioration((hull_stress + amount) - 100)
		hull_stress = mini(100, hull_stress + amount)
	else:
		hull_stress = mini(100, hull_stress + amount)
	pass

func removeHullStress(amount: int) -> void:
	hull_stress = maxi(0, hull_stress - amount)
	pass


func addHullDeterioration(amount: int) -> void:
	hull_deterioration = mini(100, hull_deterioration + amount)
	emit_signal("hullDeteriorationChanged", hull_deterioration)
	pass

func removeHullDeterioration(amount: int) -> void:
	hull_deterioration = maxi(0, hull_deterioration - amount)
	emit_signal("hullDeteriorationChanged", hull_deterioration)
	pass


func addMorale(amount: int) -> void:
	morale = mini(100, morale + amount)
	emit_signal("moraleChanged", morale)
	pass

func removeMorale(amount: int) -> void:
	morale = maxi(0, morale - amount)
	emit_signal("moraleChanged", morale)
	pass


func increaseCharacterStanding(occupation: characterAPI.OCCUPATIONS, amount: int) -> void:
	var c = get_character_with_occupation(occupation)
	if c:
		c.addStanding(amount)
	pass

func decreaseCharacterStanding(occupation: characterAPI.OCCUPATIONS, amount: int) -> void:
	var c = get_character_with_occupation(occupation)
	if c:
		c.removeStanding(amount)
	pass
