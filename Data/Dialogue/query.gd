extends Resource
class_name responseQuery

var facts: Dictionary #aka context

func add(key, value):
	facts[key] = value
	pass

func populateWithLocalData():
	pass

func populateWithPlayerData(player: playerAPI):
	add("player_speed", player.speed)
	add("player_balance", player.balance)
	add("player_current_value", player.current_value)
	
	add("player_max_jumps", player.max_jumps)
	add("player_jumps_remaining", player.jumps_remaining)
	
	for id in player.UPGRADE_ID:
		if player.unlocked_upgrades.has(player.UPGRADE_ID.get(id)):
			add(str("player_", id, "_unlocked"), true)
		else:
			add(str("player_", id, "_unlocked"), false)
	
	for character: characterAPI in [player.first_officer, player.chief_engineer, player.security_officer, player.medical_officer, player.linguist, player.historian]:
		if character:
			add(str("player_", character.OCCUPATIONS.find_key(character.get_occupation()), "_alive"), character.is_alive)
	pass

func populateWithWorldData():
	pass

func populateWithDialogueMemoryData(dialogue_memory: Dictionary):
	for fact in dialogue_memory:
		add(fact, dialogue_memory.get(fact).front())
	pass

