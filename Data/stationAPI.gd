extends bodyAPI
class_name stationAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var station_classification: int #GAME DATA 
@export var sell_percentage_of_market_price: int

func is_station():
	return true
