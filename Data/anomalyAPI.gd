extends bodyAPI
class_name anomalyAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var anomaly_classification: int #game data

enum DISCOVERY_TYPES {NORMAL, THERMAL, SONAR}
@export var discovery_type: int = 0

func is_anomaly():
	return true
