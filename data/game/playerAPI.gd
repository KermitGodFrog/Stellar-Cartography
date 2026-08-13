extends unitBodyAPI
class_name playerAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

signal hullDeteriorationChanged(new_value: int)
signal moraleChanged(new_value: int)
signal dataValueChanged(new_value: int)
signal scannerContactGained(unit: unitBodyAPI)
signal scannerContactLost(unit: unitBodyAPI)

@export var name: String
@export var ship_name: String
@export var prefix: String

@export_storage var current_star_system: starSystemAPI
@export_storage var previous_star_system: starSystemAPI

func get_adjusted_speed() -> int:
	if boosting:
		return speed * 5 * (1 + (-int(in_asteroid_belt) * 0.5)) * (1 + (-int(in_nebula) * 0.1)) * (1 + int(supercharged))
	else:
		return speed * (1 + (-int(in_asteroid_belt) * 0.5)) * (1 + (-int(in_nebula) * 0.1)) * (1 + int(supercharged))

var supercharged: bool = false:
	get():
		if supercharge_jumps_remaining > 0:
			return true
		return false

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
@export var hull_stress_pulsar_beam: int
@export var hull_stress_mine: int

@export_storage var jumps_remaining: int = 0
@export_storage var systems_traversed: int = 0
var weirdness_index :
	get:
		return remap(systems_traversed, 0, total_systems, 0.0, 1.0)

enum STORYLINES {THE_DETECTIVE, THE_CONGLOMERATE}
@export var current_storyline: STORYLINES

@export_storage var hull_deterioration: int = 0
@export_storage var hull_stress: int = 0
@export_storage var morale: int = 100:
	get:
		if survived_mutiny: return 0
		else: return morale
#@export_storage var mutiny_backing: int = 0

enum UPGRADE_ID {ADVANCED_SCANNING, AUDIO_VISUALIZER, NANITE_CONTROLLER, LONG_RANGE_SCOPES, SCAN_PREDICTION, GAS_LAYER_SURVEYOR, DRAG_DRIVES, ENVOY_PROGRAM, IMPROVED_MAGNIFICATION, ENHANCED_SCANNERS, STEALTH_COMPOSITES, BACKGROUND_PROCESSING} # REFINED_FUEL_FLOW, FASTER_PROCESSING, PRECISION_PROCESSING
@export var unlocked_upgrades: Array[UPGRADE_ID] = []
const SPL_upgrade_IDs: PackedInt32Array = [UPGRADE_ID.AUDIO_VISUALIZER, UPGRADE_ID.LONG_RANGE_SCOPES, UPGRADE_ID.GAS_LAYER_SURVEYOR]
var current_SPL_upgrades: int = 0:
	get(): #recalculate
		current_SPL_upgrades = int()
		for idx in unlocked_upgrades:
			if SPL_upgrade_IDs.has(idx):
				current_SPL_upgrades += 1
		return current_SPL_upgrades
@export var max_SPL_upgrades: int = 2
const upgrade_incompatibilities: Dictionary = {
#	UPGRADE_ID.REFINED_FUEL_FLOW: [UPGRADE_ID.DRAG_DRIVES],
#	UPGRADE_ID.FASTER_PROCESSING: [UPGRADE_ID.PRECISION_PROCESSING],
#	UPGRADE_ID.PRECISION_PROCESSING: [UPGRADE_ID.FASTER_PROCESSING]
}
const upgrade_requirements: Dictionary = {
#	UPGRADE_ID.FASTER_PROCESSING: [UPGRADE_ID.BACKGROUND_PROCESSING],
#	UPGRADE_ID.PRECISION_PROCESSING: [UPGRADE_ID.BACKGROUND_PROCESSING]
}

@export var saved_audio_profiles: Array[audioProfileHelper] = []
@export var max_saved_audio_profiles: int = 10

@export var discovered_entities: PackedInt32Array = [] #int enum identifier from game.gd, e.g - [0,5,9]
@export var discovered_gas_layers: PackedInt32Array = []

@export_storage var CME_immune: bool = false #didnt know where to put this
@export_storage var supercharge_jumps_remaining: int = 0
@export_storage var survived_mutiny: bool = false #misc
@export_storage var invulnerability_time: float = 0.0
@export_storage var action_lock: bool = false #doesnt directly do anything in this class but used by system_map to stop any actions if true

@export var characters: Array[characterAPI] = []
func get_character_with_occupation(occupation: characterAPI.OCCUPATIONS) -> characterAPI:
	for c in characters:
		if c.get_occupation() == occupation:
			return c
	return null

enum SCOPE_MODES {VIS, RAD}

#unitBodyAPI detection ranges
@export var scanner_profile: float #how far away OTHER ships have to be to detect you
func get_adjusted_scanner_profile() -> float:
	var multiplier = 1.0
	
	if in_asteroid_belt:
		multiplier -= 0.7
	if in_pulsar_beam:
		multiplier -= 0.8
	if boosting:
		multiplier += 0.2
	
	return maxf(10.0, scanner_profile * maxf(0, multiplier))
@export var scanner_power: float #detection range of OTHER ships in solar radii
func get_adjusted_scanner_power() -> float:
	var multiplier = 1.0
	
	if in_asteroid_belt:
		multiplier -= 0.75
	if in_pulsar_beam:
		multiplier -= 0.5
	if in_nebula:
		multiplier -= 0.5
	
	return maxf(10.0, scanner_power * maxf(0, multiplier))

var scanner_contacts: Array[unitBodyAPI] = []

@export_storage var analytics_exploration_data_payouts: PackedInt32Array = []

@export_storage var sys_survey_value: int = 0
@export_storage var sys_survey_time_start: float = 0.0 
@export_storage var sys_survey_hit_pings: int = 0 
@export_storage var sys_survey_total_pings: int = 0 
var sys_survey_ping_ratio: float = 0.0:
	get():
		if sys_survey_total_pings != 0: #avoiding division by 0 error
			return float(sys_survey_hit_pings) / float(sys_survey_total_pings)
		else:
			return float()
func reset_all_sys_survey_data() -> void:
	sys_survey_value = int()
	sys_survey_time_start = float()
	sys_survey_hit_pings = int()
	sys_survey_total_pings = int()
	pass



func get_jumps_remaining():
	return jumps_remaining

func get_max_jumps():
	return max_jumps

func set_max_jumps(value: int):
	max_jumps = value
	pass



func setTargetPosition(pos: Vector2):
	target_position = pos
	pass



func resetJumpsRemaining():
	jumps_remaining = max_jumps
	pass

func removeJumpsRemaining(amount: int):
	jumps_remaining = maxi(0, jumps_remaining - amount)
	supercharge_jumps_remaining = maxi(0, supercharge_jumps_remaining - amount)
	pass

func addJumpsRemaining(amount: int):
	jumps_remaining = mini(max_jumps, jumps_remaining + amount)
	pass




func unlockUpgrade(upgrade_idx: UPGRADE_ID) -> int:
	if not unlocked_upgrades.has(upgrade_idx):
		unlocked_upgrades.append(upgrade_idx)
		return upgrade_idx
	return -1

func lockUpgrade(upgrade_idx: UPGRADE_ID) -> int:
	if unlocked_upgrades.has(upgrade_idx):
		unlocked_upgrades.erase(upgrade_idx)
		return upgrade_idx
	return -1

func get_unlocked_upgrades() -> Array[UPGRADE_ID]:
	return unlocked_upgrades

func get_upgrade_unlocked_state(upgrade_idx: UPGRADE_ID) -> bool:
	if unlocked_upgrades.has(upgrade_idx):
		return true
	else:
		return false

func is_upgrade_unlock_valid(upgrade_idx: UPGRADE_ID) -> bool:
	var unlocked: bool = get_upgrade_unlocked_state(upgrade_idx) #must be false
	var SPL_above_max: bool = false #must be false
	var incompatible: bool = false
	var requirements_unmet: bool = false
	
	if SPL_upgrade_IDs.has(upgrade_idx):
		if current_SPL_upgrades >= max_SPL_upgrades:
			SPL_above_max = true
	
	var incompatibilities = upgrade_incompatibilities.get(upgrade_idx)
	if incompatibilities != null:
		for u in incompatibilities:
			if get_upgrade_unlocked_state(u) == true:
				incompatible = true
	
	var requirements = upgrade_requirements.get(upgrade_idx)
	if requirements != null:
		requirements_unmet = !requirements.all(get_upgrade_unlocked_state)
	
	if (unlocked == false) and (SPL_above_max == false) and (incompatible == false) and (requirements_unmet == false):
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

func addValue(amount: int) -> void:
	current_value += amount
	pass

func removeValue(amount: int) -> void:
	current_value = maxi(0, current_value - amount)
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

func modifyCharacterStanding(_occupation: characterAPI.OCCUPATIONS, _amount: int, increase: bool) -> void:
	match increase:
		true:
			increaseCharacterStanding(_occupation, _amount)
		false:
			decreaseCharacterStanding(_occupation, _amount)
	pass




func addCharacterXP(occupation: characterAPI.OCCUPATIONS, amount: int) -> void:
	var c = get_character_with_occupation(occupation)
	if c:
		c.add_xp(amount)
	pass

func removeCharacterInitiativeXP(occupation: characterAPI.OCCUPATIONS) -> void:
	var c = get_character_with_occupation(occupation)
	if c:
		c.remove_initiative_xp()
	pass




func updateScannerContacts(r_contacts: Array[unitBodyAPI]) -> void:
	var gained_contacts: Array[unitBodyAPI] = r_contacts.filter(func(c): return not scanner_contacts.has(c))
	var lost_contacts: Array[unitBodyAPI] = scanner_contacts.filter(func(c): return not r_contacts.has(c))
	for c in gained_contacts:
		emit_signal("scannerContactGained", c)
	for c in lost_contacts:
		emit_signal("scannerContactLost", c)
	scanner_contacts = r_contacts
	pass




func is_invulnerable() -> bool:
	if invulnerability_time > 0:
		return true
	return false

func grant_invulnerability(time: float) -> void:
	invulnerability_time += time
	pass

func tick_invulnerability_time(delta) -> void:
	invulnerability_time = maxf(0.0, invulnerability_time - delta)
	pass
