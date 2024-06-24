extends bodyAPI
class_name stationAPI
enum STATION_CLASSIFICATIONS {STANDARD, TRADE, MILITARY}
var station_classification: int
var sell_percentage_of_market_price: int

func is_station():
	return true

func stringify_station_classification():
	var stringified_classification: String
	match station_classification:
		STATION_CLASSIFICATIONS.STANDARD:
			stringified_classification = "Standard"
		STATION_CLASSIFICATIONS.TRADE:
			stringified_classification = "Trade"
		STATION_CLASSIFICATIONS.MILITARY:
			stringified_classification = "Military"
		_:
			stringified_classification = ""
	return stringified_classification
