extends bodyAPI
class_name stationAPI
enum STATION_CLASSIFICATIONS {STANDARD, PIRATE, ABANDONED, COVERUP, DEBRIS, ABANDONED_OPERATIONAL, ABANDONED_BACKROOMS, PARTIALLY_SALVAGED, BIRD}
var station_classification: int
var sell_percentage_of_market_price: int

func is_station():
	return true
