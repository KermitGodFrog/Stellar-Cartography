extends glintBodyAPI
class_name stationBodyAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var station_classification: game_data.STATION_CLASSIFICATIONS #GAME DATA 
@export var sell_percentage_of_market_price: int
@export var module_store_disabled: bool = false # <- shouldnt have 'is' in variable name

@export var excluded_upgrades: Array[playerAPI.UPGRADE_ID] = []
