extends bodyAPI
class_name anomalyAPI
enum ANOMALY_TYPES {SPACE_WHALE_POD, LAGRANGE_CLOUD}
var anomaly_type
enum DISCOVERY_TYPES {NORMAL, THERMAL, SONAR}
var discovery_type

func is_anomaly():
	return true
