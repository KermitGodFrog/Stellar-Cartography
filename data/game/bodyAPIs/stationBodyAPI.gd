extends glintBodyAPI
class_name stationBodyAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var station_classification: game_data.STATION_CLASSIFICATIONS #GAME DATA 
@export var sell_percentage_of_market_price: int
@export var repair_price_multiplier: float = 1.0
@export var module_store_disabled: bool = false # <- shouldnt have 'is' in variable name

@export var available_upgrades: Array[playerAPI.UPGRADE_ID] = []

func exclude_upgrade(upgrade_idx: playerAPI.UPGRADE_ID) -> void: #safe way to quick remove upgrades if they exist ... starSystemAPI cant use it because it has to do all calculations before the body is made and thus this method is accessible :(
	if available_upgrades.has(upgrade_idx):
		available_upgrades.erase(upgrade_idx)
	pass
