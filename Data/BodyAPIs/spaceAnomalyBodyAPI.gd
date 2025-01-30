extends glintBodyAPI
class_name spaceAnomalyBodyAPI

func is_SA_valid() -> bool:
	if (metadata.get("is_space_anomaly_available", true) == true):
		return true
	return false
