extends bodyAPI
class_name anomalyAPI
var anomaly_classification: int #game data

enum DISCOVERY_TYPES {NORMAL, THERMAL, SONAR}
var discovery_type: int = 0

func is_anomaly():
	return true
