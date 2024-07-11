extends Node
#DISPLAYS PLAYER VALUE AND PLAYER BALANCE - DOES NOT CHANGE IT

var station: stationAPI
var player_current_value: int
var player_balance: int

#FOR AUDIO VISUALIZER \/\/\/\/\/
var pending_audio_profiles: Array[audioProfileHelper] = []
var player_saved_audio_profiles_size_matrix: Array = [] #current, max

signal sellExplorationData(sell_percentage_of_market_price: int)
signal upgradeShip(upgrade_idx: playerAPI.UPGRADE_ID, cost: int)
signal undockFromStation(from_station: stationAPI)
signal addSavedAudioProfile(helper: audioProfileHelper)

@onready var sell_data_button = $sell_data_button
@onready var balance_label = $balance_label
@onready var save_audio_profiles_control = $save_audio_profiles_control
@onready var observed_bodies_list = $save_audio_profiles_control/margin/panel/panel_margin/save_audio_profiles_scroll/observed_bodies_list

var has_sold_previously: bool = false

func _ready():
	observed_bodies_list.connect("saveAudioProfile", _on_audio_profile_saved)
	pass

func _physics_process(_delta):
	print_debug(player_saved_audio_profiles_size_matrix)
	if station:
		sell_data_button.set_text(str("SELL EXPLORATION DATA\n", player_current_value, "c\n(", station.sell_percentage_of_market_price, "% OF MARKET PRICE)"))
		balance_label.set_text(str("BALANCE: ", player_balance, "c"))
	pass

func _on_sell_data_button_pressed():
	if station and not has_sold_previously:
		has_sold_previously = true
		emit_signal("sellExplorationData", station.sell_percentage_of_market_price)
		if pending_audio_profiles:
			observed_bodies_list.initialize(pending_audio_profiles)
			save_audio_profiles_control.show()
	pass

func _on_undock_button_pressed():
	pending_audio_profiles = []
	if station: emit_signal("undockFromStation", station)
	else: emit_signal("undockFromStation", null)
	get_tree().paused = false
	pass

func _on_audio_profile_saved(helper: audioProfileHelper):
	if player_saved_audio_profiles_size_matrix.front() < player_saved_audio_profiles_size_matrix.back():
		emit_signal("addSavedAudioProfile", helper)
	else:
		#ui elemnts flash and stuff
		pass
	pass

func _on_finished_button_pressed():
	save_audio_profiles_control.hide()
	pass 



func _on_unlock_advanced_scanning_button_pressed():
	if station: 
		emit_signal("upgradeShip", playerAPI.UPGRADE_ID.ADVANCED_SCANNING, 20000)
	pass

func _on_unlock_audio_visualizer_pressed():
	if station:
		emit_signal("upgradeShip", playerAPI.UPGRADE_ID.AUDIO_VISUALIZER, 30000)
	pass

