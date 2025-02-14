extends Resource
class_name responseQuery

var facts: Dictionary #aka context
var tree_access_facts: Dictionary

func add(key, value):
	facts[key] = value
	pass

func add_tree_access(key, value):
	add(key, value)
	tree_access_facts[key] = value
	pass

func populateWithLocalData():
	pass

func populateWithPlayerData(player: playerAPI):
	add("player_name", player.name)
	add("player_prefix", player.prefix)
	add("player_prefix_lower", player.prefix.to_lower())
	
	add("player_speed", player.speed)
	add("player_balance", player.balance)
	add("player_current_value", player.current_value)
	add("player_total_score", player.total_score)
	
	add("player_max_jumps", player.max_jumps)
	add("player_jumps_remaining", player.jumps_remaining)
	
	add("player_weirdness_index", player.weirdness_index)
	add("player_current_storyline", player.current_storyline)
	
	add("player_hull_deterioration", player.hull_deterioration)
	add("player_hull_stress", player.hull_stress)
	add("player_morale", player.morale)
	
	var in_CORE_region: bool = false
	var in_FRONTIER_region: bool = false
	var in_ABYSS_region: bool = false
	var in_CORE_or_FRONTIER_region: bool = false
	var in_FRONTIER_or_ABYSS_region: bool = false
	var in_ANY_region: bool = false
	
	if player.weirdness_index >= 0.2 and player.weirdness_index < 0.6: in_FRONTIER_region = true
	elif player.weirdness_index >= 0.6: in_ABYSS_region = true
	else: in_CORE_region = true
	
	if in_CORE_region or in_FRONTIER_region:
		in_CORE_or_FRONTIER_region = true
	
	if in_FRONTIER_region or in_ABYSS_region:
		in_FRONTIER_or_ABYSS_region = true
	
	if in_CORE_region or in_FRONTIER_region or in_ABYSS_region:
		in_ANY_region = true
	
	add("player_in_CORE_region", in_CORE_region)
	add("player_in_FRONTIER_region", in_FRONTIER_region)
	add("player_in_ABYSS_region", in_ABYSS_region)
	add("player_in_CORE_or_FRONTIER_region", in_CORE_or_FRONTIER_region)
	add("player_in_FRONTIER_or_ABYSS_region", in_FRONTIER_or_ABYSS_region)
	add("player_in_ANY_region", in_ANY_region)
	
	for id in player.UPGRADE_ID:
		if player.unlocked_upgrades.has(player.UPGRADE_ID.get(id)):
			add(str("player_", id, "_unlocked"), true)
		else:
			add(str("player_", id, "_unlocked"), false)
	
	for character in player.characters:
		add(str("player_", characterAPI.OCCUPATIONS.find_key(character.get_occupation()), "_alive"), character.is_alive())
	pass

func populateWithSystemData(system: starSystemAPI):
	add("system_is_civilized", system.is_civilized())
	pass

func populateWithWorldData():
	add("randi", randi())
	add("randf", randf())
	add("RAND_50%", randf() > 0.5)
	add("RAND_10%", randf() > 0.9)
	add("RAND_90%", randf() > 0.1)
	pass

func populateWithDialogueMemoryData(dialogue_memory: Dictionary):
	for fact in dialogue_memory:
		add(fact, dialogue_memory.get(fact))
	pass

func populateWithTreeAccessMemoryData(tree_access_memory: Dictionary):
	for fact in tree_access_memory:
		add(fact, tree_access_memory.get(fact))
	pass
