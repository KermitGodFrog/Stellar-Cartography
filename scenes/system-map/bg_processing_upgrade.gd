extends Node2D

@onready var cooldown = $cooldown

var ping_cooldown: float = 60.0:
	set(value):
		ping_cooldown = value
		cooldown.set_wait_time(ping_cooldown)
var ping_radius: float = 125.0
var draw_pings: bool = false
const ping_outline_size: float = 10.0

var PINGS: Array[pingDisplayHelper]

var _system: starSystemAPI:
	set(value):
		var changed: bool = false
		if _system != value:
			changed = true
		_system = value
		if changed:
			cooldown.start()
func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == playerAPI.UPGRADE_ID.BACKGROUND_PROCESSING:
		draw_pings = state
	pass

func _physics_process(delta: float) -> void:
	for ping in PINGS:
		ping.updateTime(delta)
		if ping.is_expired():
			PINGS.erase(ping)
	
	if draw_pings:
		queue_redraw()
	pass

func _draw() -> void:
	for ping in PINGS:
		ping.updateDisplay()
		draw_circle(ping.position, ping_radius * ping.current_radius, ping.current_color, false, ping_outline_size)
	pass

func _on_cooldown_timeout() -> void:
	if draw_pings and _system.get_first_star().metadata.get("star_type") not in ["M", "K", "G", "Pulsar"]:
		var ping: pingDisplayHelper = load("uid://dtbys0v13sstc").duplicate(true)
		
		var potential_targets: Array[orbitBodyAPI] = []
		for b in _system.bodies:
			if b is orbitBodyAPI:
				if not b.is_hidden():
					if (not b.is_theorised()) and (not b.is_known()):
						potential_targets.append(b)
		
		if potential_targets.size() > 0:
			var target: orbitBodyAPI = potential_targets.pick_random()
			ping.position = target.position + Vector2(0.0, global_data.get_randf(0.0, ping_radius - (ping_outline_size / 2.0) - (ping_radius * 0.1))).rotated(deg_to_rad(global_data.get_randf(0,360)))
			ping.resetTime()
			PINGS.append(ping)
			get_tree().call_group("audioHandler", "play_once", load("uid://ddcqj11jyfxnl"), -6.0, "SFX")
	pass 
