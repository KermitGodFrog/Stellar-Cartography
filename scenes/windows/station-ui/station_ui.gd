extends Node
#DISPLAYS PLAYER VALUE AND PLAYER BALANCE - DOES NOT CHANGE IT
#all values displayed here are updated BY GAME.GD whenever the relevant signals are received. E.g, sell exploration data signal is sent and game.gd updates the local player balance. its all updated as soon as it opens as well

var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		_pause_mode = value
		_on_pause_mode_changed(value)
signal queuePauseMode(new_mode: game_data.PAUSE_MODES)
signal setPauseMode(new_mode: game_data.PAUSE_MODES)
func _on_pause_mode_changed(value):
	match value:
		game_data.PAUSE_MODES.NONE:
			has_sold_previously = false
			get_node(window).hide()
		game_data.PAUSE_MODES.STATION_UI:
			get_node(window).popup()
			get_node(window).move_to_center()
			_on_popup()
	pass



const upgrade_data = {
	playerAPI.UPGRADE_ID.ADVANCED_SCANNING: {"cost": 7500, "description": "Advanced scanning capability. Increases the chance to detect planetary and space anomalies by 10%."},
	playerAPI.UPGRADE_ID.AUDIO_VISUALIZER: {"cost": 35000, "description": "(SPECIAL) Audio visualisation software. Allows analysis of planetary composition by accounting for the noise a planet produces. Nanite rewards are paid to correct estimation of planetary composition."},
	playerAPI.UPGRADE_ID.NANITE_CONTROLLER: {"cost": 25000, "description": "Nanite control capability - made possible by specialised infrastructure and software. Allows repairs to be conducted outside of a port, at a greatly increased nanite cost."},
	playerAPI.UPGRADE_ID.LONG_RANGE_SCOPES: {"cost": 35000, "description": "(SPECIAL) Longer range scopes. Allow Stellar Phenomena to be photographed. Nanite rewards are paid for photos of quality, which take the photography style for different phenomena into account."},
	playerAPI.UPGRADE_ID.SCAN_PREDICTION: {"cost": 7500, "description": "Scan prediction algorithms. Allow LIDAR scan arcs to be visible on the SYSTEM MAP before the 'PING' button is pressed."},
	playerAPI.UPGRADE_ID.GAS_LAYER_SURVEYOR: {"cost": 35000, "description": "(SPECIAL) Gas layer surveying capability - made possible by improved antennae and specialised probe manufactories. Probes are built to survive the crushing pressure of Neptunian and Jovian worlds. Nanite rewards are paid for correctly identifying the gas layers that probes traverse."}
}

var station: stationBodyAPI
var player_current_value: int = 0
var player_balance: int = 0
var player_hull_stress: int = 0
var player_SPL_upgrades_matrix: Array = [] #current, max
var player_unlocked_upgrades: Array[playerAPI.UPGRADE_ID] = []
var nanites_per_percentage: int = 100

#FOR AUDIO VISUALIZER \/\/\/\/\/
var pending_audio_profiles: Array = []:
	set(value):
		pending_audio_profiles = value
		print("PENDING AUDIO PROFILES ", pending_audio_profiles)
var player_saved_audio_profiles_size_matrix: Array = [] #current, max

signal sellExplorationData(sell_percentage_of_market_price: int)
signal upgradeShip(upgrade_idx: playerAPI.UPGRADE_ID, cost: int)
signal addSavedAudioProfile(helper: audioProfileHelper)
signal removeHullStressForNanites(amount: int, _nanites_per_percentage: int)
signal addPlayerValue(amount: int)

@export var window: NodePath

@onready var sell_data_button = $sell_data_button
@onready var balance_label = $balance_label
@onready var save_audio_profiles_control = $save_audio_profiles_control
@onready var observed_bodies_list = $save_audio_profiles_control/margin/panel/panel_margin/save_audio_profiles_scroll/observed_bodies_list
@onready var save_audio_profiles_info_label = $save_audio_profiles_control/margin/panel/panel_margin/save_audio_profiles_scroll/info_label
@onready var storage_progress_bar = $save_audio_profiles_control/margin/panel/panel_margin/save_audio_profiles_scroll/storage_progress_bar
#upgrade shtuff
@onready var description_label = $upgrade_container/description_label
@onready var disclaimer_label = $upgrade_container/disclaimer_label
@onready var SPL_disclaimer_label = $upgrade_container/SPL_disclaimer_label
@onready var UPGRADES = $upgrade_container/UPGRADES
@onready var UNLOCKED_UPGRADES = $upgrade_container/unlocked_upgrades_container/UNLOCKED_UPGRADES

@onready var hull_stress_label = $repair_container/hull_stress_label
@onready var repair_single_button = $repair_container/repair_single
@onready var repair_all_button = $repair_container/repair_all

@onready var background_animation = $background_center/background_container/background_viewport/station_ui_background/animation_player

@onready var tutorial = $tutorial

@onready var upgrade_button_scene = preload("uid://c3wfhxfh1cg8d")

@onready var station_upgrade = preload("uid://crt73kp6x2bbe")
@onready var station_sell_data = preload("uid://bbdwwjno15wk3")
@onready var station_repair = preload("uid://dha2d3lx22sd1")

var has_sold_previously: bool = false
const sell_upgrade_price_multiplier = 0.25

func _ready():
	observed_bodies_list.connect("saveAudioProfile", _on_audio_profile_saved)
	observed_bodies_list.connect("_addPlayerValue", _on_add_player_value)
	observed_bodies_list.connect("finishedButtonPressed", _on_finished_button_pressed)
	pass

func _physics_process(_delta):
	if station:
		nanites_per_percentage = game_data.REPAIR_CURVE.sample(game_data.player_weirdness_index) #we are using too many global vars here its not very cool and stuff dont like it feel like im a rookie yknow 
		
		balance_label.set_text(str("BALANCE: ", player_balance, "n"))
		hull_stress_label.set_text(str("HULL STRESS: ", player_hull_stress, "%"))
		
		if not has_sold_previously:
			sell_data_button.set_text(str("SELL EXPLORATION DATA\n", int(player_current_value * (station.sell_percentage_of_market_price / 100.0)), "n\n(", station.sell_percentage_of_market_price, "% OF MARKET PRICE)"))
		elif has_sold_previously: sell_data_button.set_text("SOLD")
		
		repair_single_button.set_text(str("REPAIR 1% (", nanites_per_percentage, "n)"))
		repair_all_button.set_text(str("REPAIR ", player_hull_stress, "% (", (player_hull_stress * nanites_per_percentage), "n)"))
		
		SPL_disclaimer_label.set_text("(%.f/%.f SPECIAL UPGRADES)" % [player_SPL_upgrades_matrix[0], player_SPL_upgrades_matrix[1]])
	
	#saved audio profiles control:
	if player_saved_audio_profiles_size_matrix:
		storage_progress_bar.set_max(player_saved_audio_profiles_size_matrix.back())
		storage_progress_bar.set_value(player_saved_audio_profiles_size_matrix.front())
	pass

func _on_sell_data_button_pressed():
	if station and not has_sold_previously:
		has_sold_previously = true
		emit_signal("sellExplorationData", station.sell_percentage_of_market_price)
		get_tree().call_group("audioHandler", "play_once", station_sell_data, 0.0, "SFX")
		
		if pending_audio_profiles:
			observed_bodies_list.initialize(pending_audio_profiles)
			save_audio_profiles_control.show()
	pass


func _on_audio_profile_saved(helper: audioProfileHelper):
	emit_signal("addSavedAudioProfile", helper)
	pass

func _on_finished_button_pressed():
	save_audio_profiles_control.hide()
	emit_signal("sellExplorationData", station.sell_percentage_of_market_price)
	pass 


func _on_repair_single_pressed():
	if (player_balance >= nanites_per_percentage) and (player_hull_stress > 0): #terrible stupid thing ... shouldnt be computing this redundantly... game.gd _on_remove_hull_stress_for_nanites
		get_tree().call_group("audioHandler", "play_once", station_repair, -12.0, "SFX")
	
	emit_signal("removeHullStressForNanites", 1, nanites_per_percentage)
	pass

func _on_repair_all_pressed():
	if (player_balance >= player_hull_stress * nanites_per_percentage) and (player_hull_stress > 0): #terrible stupid thing ... shouldnt be computing this redundantly... game.gd _on_remove_hull_stress_for_nanites
		get_tree().call_group("audioHandler", "play_once", station_repair, -12.0, "SFX")
	
	emit_signal("removeHullStressForNanites", player_hull_stress, nanites_per_percentage)
	pass

func _on_add_player_value(amount: int):
	emit_signal("addPlayerValue", amount)
	pass


func _on_station_window_close_requested():
	get_tree().call_group("audioHandler", "plot_radio", load("uid://bx2vg1aj6oo03"))
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass

func _on_popup():
	var animations = ["starship_in_alt", "starship_in2", "starship_in3"]
	if background_animation.current_animation: animations.erase(background_animation.current_animation)
	background_animation.play("RESET")
	background_animation.play(animations.pick_random())
	
	for c in UNLOCKED_UPGRADES.get_children():
		c.queue_free()
	for c in UPGRADES.get_children():
		c.queue_free()
	
	if station:
		save_audio_profiles_info_label.set_text("The wider astronomical community on %s has analyzed the legitimacy of additional observations you have inferred on unknown bodies during your travels." % station.get_display_name())
		add_relevant_upgrade_buttons()
	pass


func add_relevant_upgrade_buttons() -> void:
	for upgrade in playerAPI.UPGRADE_ID.values():
		if player_unlocked_upgrades.has(upgrade):
			add_upgrade_button(upgrade, true)
		elif not station.excluded_upgrades.has(upgrade):
			add_upgrade_button(upgrade, false)
	pass

func add_upgrade_button(upgrade: playerAPI.UPGRADE_ID, unlocked: bool) -> void:
	#for upgrade in playerAPI.UPGRADE_ID.values(): #.filter(func(u): return not station.excluded_modules.has(u)):
	var data = upgrade_data.get(upgrade)
	var instance = upgrade_button_scene.instantiate()
	instance.upgrade = upgrade
	instance.unlocked = unlocked
	instance._sell_upgrade_price_multiplier = sell_upgrade_price_multiplier
	
	instance.cost = data.get("cost")
	instance.description = data.get("description")
	instance.connect("pressed", _on_upgrade_pressed.bind(instance.upgrade, instance.cost, instance.unlocked))
	instance.connect("mouse_entered", _on_upgrade_mouse_entered.bind(instance.description))
	
	match instance.unlocked:
		true:
			UNLOCKED_UPGRADES.add_child(instance)
		false:
			UPGRADES.add_child(instance)
	pass

func update_upgrade_buttons() -> void:
	if station:
		for c in UNLOCKED_UPGRADES.get_children():
			if not player_unlocked_upgrades.has(c.upgrade):
				if not station.excluded_upgrades.has(c.upgrade):
					add_upgrade_button(c.upgrade, false)
				c.queue_free()
		for c in UPGRADES.get_children():
			if player_unlocked_upgrades.has(c.upgrade):
				add_upgrade_button(c.upgrade, true)
				c.queue_free()
	pass


func _on_upgrade_mouse_entered(description: String) -> void:
	description_label.set_text(description)
	pass

func _on_upgrade_pressed(upgrade_idx: playerAPI.UPGRADE_ID, cost: int, already_unlocked: bool):
	if station: 
		if already_unlocked:
			# SELL UPGRADE HERE!
			#emit_signal("sellUpgrade", upgrade_idx, refund)
			pass
		else:
			if not station.module_store_disabled:
				emit_signal("upgradeShip", upgrade_idx, cost)
			else:
				disclaimer_label.blink(Color.RED)
	pass




func _on_disable_module_store() -> void:
	if station:
		station.set("module_store_disabled", true)
		get_tree().call_group("audioHandler", "play_once", station_upgrade, 0.0, "SFX") #assumes that every time the module store is disabled, its ALWAYS because a module is bought. pay attention to this 
	pass

func _on_set_tutorial_visible(value: bool) -> void:
	tutorial.set_visible(value)
	pass
