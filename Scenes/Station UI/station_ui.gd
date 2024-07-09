extends Node
#DISPLAYS PLAYER VALUE AND PLAYER BALANCE - DOES NOT CHANGE IT

var station: stationAPI
var player_current_value: int
var player_balance: int

signal sellExplorationData(sell_percentage_of_market_price: int)
signal upgradeShip(upgrade_idx: playerAPI.UPGRADE_ID, cost: int)
signal undockFromStation(from_station: stationAPI)

@onready var sell_data_button = $sell_data_button
@onready var balance_label = $balance_label

func _physics_process(_delta):
	if station:
		sell_data_button.set_text(str("SELL EXPLORATION DATA\n", player_current_value, "c\n(", station.sell_percentage_of_market_price, "% OF MARKET PRICE)"))
		balance_label.set_text(str("BALANCE: ", player_balance, "c"))
	pass

func _on_sell_data_button_pressed():
	if station: emit_signal("sellExplorationData", station.sell_percentage_of_market_price)
	pass

func _on_undock_button_pressed():
	if station: emit_signal("undockFromStation", station)
	else: emit_signal("undockFromStation", null)
	get_tree().paused = false
	pass







func _on_unlock_advanced_scanning_button_pressed():
	if station: 
		emit_signal("upgradeShip", playerAPI.UPGRADE_ID.ADVANCED_SCANNING, 20000)
	pass

func _on_unlock_audio_visualizer_pressed():
	if station:
		emit_signal("upgradeShip", playerAPI.UPGRADE_ID.AUDIO_VISUALIZER, 30000)
	pass
