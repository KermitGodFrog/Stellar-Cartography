extends Node
#DISPLAYS PLAYER VALUE AND PLAYER BALANCE - DOES NOT CHANGE IT
#all values displayed here are updated BY GAME.GD whenever the relevant signals are received. E.g, sell exploration data signal is sent and game.gd updates the local player balance. its all updated as soon as it opens as well

var station: stationAPI
var player_current_value: int
var player_balance: int
var player_hull_stress: int 
var nanites_per_percentage: int = 100

#FOR AUDIO VISUALIZER \/\/\/\/\/
var pending_audio_profiles: Array[audioProfileHelper] = []
var player_saved_audio_profiles_size_matrix: Array = [] #current, max

signal sellExplorationData(sell_percentage_of_market_price: int)
signal upgradeShip(upgrade_idx: playerAPI.UPGRADE_ID, cost: int)
signal undockFromStation(from_station: stationAPI)
signal addSavedAudioProfile(helper: audioProfileHelper)
signal removeHullStressForNanites(amount: int, _nanites_per_percentage: int)

@onready var sell_data_button = $sell_data_button
@onready var balance_label = $balance_label
@onready var save_audio_profiles_control = $save_audio_profiles_control
@onready var observed_bodies_list = $save_audio_profiles_control/margin/panel/panel_margin/save_audio_profiles_scroll/observed_bodies_list
@onready var storage_progress_bar = $save_audio_profiles_control/margin/panel/panel_margin/save_audio_profiles_scroll/storage_progress_bar
#upgrade buttons
@onready var unlock_advanced_scanning_button = $upgrade_container/unlock_advanced_scanning
@onready var unlock_audio_visualizer_button = $upgrade_container/unlock_audio_visualizer
@onready var unlock_nanite_controller_button = $upgrade_container/unlock_nanite_controller
@onready var unlock_long_range_scopes_button = $upgrade_container/unlock_long_range_scopes

@onready var hull_stress_label = $repair_container/hull_stress_label
@onready var repair_single_button = $repair_container/repair_single
@onready var repair_all_button = $repair_container/repair_all

@onready var background_animation = $background_center/background_container/background_viewport/station_ui_background/animation_player

var has_sold_previously: bool = false

func _ready():
	observed_bodies_list.connect("saveAudioProfile", _on_audio_profile_saved)
	pass

func _physics_process(_delta):
	if station:
		nanites_per_percentage = game_data.REPAIR_CURVE.sample(game_data.player_weirdness_index) #we are using too many global vars here its not very cool and stuff dont like it feel like im a rookie yknow 
		
		balance_label.set_text(str("BALANCE: ", player_balance, "n"))
		hull_stress_label.set_text(str("HULL STRESS: ", player_hull_stress, "%"))
		
		if not has_sold_previously:
			sell_data_button.set_text(str("SELL EXPLORATION DATA\n", player_current_value * (station.sell_percentage_of_market_price / 100.0), "n\n(", station.sell_percentage_of_market_price, "% OF MARKET PRICE)"))
		elif has_sold_previously: sell_data_button.set_text("SOLD")
		
		repair_single_button.set_text(str("REPAIR 1% (", nanites_per_percentage, "n)"))
		repair_all_button.set_text(str("REPAIR ", player_hull_stress, "% (", (player_hull_stress * nanites_per_percentage), "n)"))
		
	#saved audio profiles control:
	if player_saved_audio_profiles_size_matrix:
		storage_progress_bar.set_max(player_saved_audio_profiles_size_matrix.back())
		storage_progress_bar.set_value(player_saved_audio_profiles_size_matrix.front())
	pass

func _on_sell_data_button_pressed():
	if station and not has_sold_previously:
		has_sold_previously = true
		emit_signal("sellExplorationData", station.sell_percentage_of_market_price)
		if pending_audio_profiles:
			observed_bodies_list.initialize(pending_audio_profiles)
			save_audio_profiles_control.show()
	pass

func _on_audio_profile_saved(helper: audioProfileHelper):
	emit_signal("addSavedAudioProfile", helper)
	pass

func _on_finished_button_pressed():
	save_audio_profiles_control.hide()
	pass 



func _on_unlock_advanced_scanning_button_pressed():
	if station: 
		emit_signal("upgradeShip", playerAPI.UPGRADE_ID.ADVANCED_SCANNING, 7500) #formerly 10000 (probably more balanced)
	pass

func _on_unlock_audio_visualizer_pressed():
	if station:
		emit_signal("upgradeShip", playerAPI.UPGRADE_ID.AUDIO_VISUALIZER, 35000) #formerly 85000 (probably more balanced)
	pass

func _on_unlock_nanite_controller_pressed():
	if station:
		emit_signal("upgradeShip", playerAPI.UPGRADE_ID.NANITE_CONTROLLER, 25000) #formerly 45000 (probably more balanced)
	pass 

func _on_unlock_long_range_scopes_pressed():
	if station:
		emit_signal("upgradeShip", playerAPI.UPGRADE_ID.LONG_RANGE_SCOPES, 35000) #formerly 85000 (probably more balanced)
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	match upgrade_idx:
		playerAPI.UPGRADE_ID.ADVANCED_SCANNING:
			match state:
				true:
					unlock_advanced_scanning_button.set_text("ADVANCED SCANNING: UNLOCKED")
				false:
					unlock_advanced_scanning_button.set_text("ADVANCED SCANNING: 30000n")
		playerAPI.UPGRADE_ID.AUDIO_VISUALIZER:
			match state:
				true:
					unlock_audio_visualizer_button.set_text("AUDIO VISUALIZER: UNLOCKED")
				false:
					unlock_audio_visualizer_button.set_text("AUDIO VISUALIZER: 20000n (REQ ADVANCED SCANNING)")
		playerAPI.UPGRADE_ID.NANITE_CONTROLLER:
			match state:
				true:
					unlock_nanite_controller_button.set_text("NANITE CONTROLLER: UNLOCKED")
				false:
					unlock_nanite_controller_button.set_text("NANITE CONTROLLER: 10000n")
		playerAPI.UPGRADE_ID.LONG_RANGE_SCOPES:
			match state:
				true:
					unlock_long_range_scopes_button.set_text("LONG RANGE SCOPES: UNLOCKED")
				false:
					unlock_long_range_scopes_button.set_text("LONG RANGE SCOPES: 40000n")
		var error:
			print_debug(str("STATION UI: ERROR: BUTTON TEXT CHANGE FOR UPGRADE IDX ", error, "NOT CONFIGURED!"))
	pass



func _on_repair_single_pressed():
	emit_signal("removeHullStressForNanites", 1, nanites_per_percentage)
	pass

func _on_repair_all_pressed():
	emit_signal("removeHullStressForNanites", player_hull_stress, nanites_per_percentage)
	pass



func _on_station_window_close_requested():
	has_sold_previously = false
	pending_audio_profiles = []
	if station: emit_signal("undockFromStation", station)
	else: emit_signal("undockFromStation", null)
	get_tree().paused = false
	pass

func _on_popup():
	var animations = ["starship_in_alt", "starship_in2", "starship_in3"]
	if background_animation.current_animation: animations.erase(background_animation.current_animation)
	background_animation.play("RESET")
	background_animation.play(animations.pick_random())
	pass
