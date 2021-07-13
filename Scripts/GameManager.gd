extends Node

onready var explosion = load("res://Scenes/Explosion.tscn")
onready var boss_marker = load("res://Scenes/BossMarker.tscn").instance()
onready var splatter_particles = load("res://Scenes/SplatterParticles.tscn")

onready var shotgun_bot = load("res://Scenes/ShotgunnerBot.tscn")
onready var wheel_bot = load("res://Scenes/WheelBot.tscn")
onready var archer_bot = load("res://Scenes/ArcherBot.tscn")
onready var chain_bot = load("res://Scenes/ChainBot.tscn")
onready var flame_bot = load("res://Scenes/FlamethrowerBot.tscn")
onready var exterminator_bot = load("res://Scenes/ExterminatorBot.tscn")
onready var sorcerer_bot = load("res://Scenes/SorcererBot.tscn")
onready var saber_bot = load("res://Scenes/SaberBot.tscn")
onready var viewport = get_viewport()

onready var enemies = [shotgun_bot, wheel_bot, archer_bot, chain_bot, flame_bot, exterminator_bot, sorcerer_bot, saber_bot]

onready var SFX = AudioStreamPlayer.new()
onready var swap_unlock_sound = load("res://Sounds/SoundEffects/Wub1.wav")

signal on_swap

const levels = {
	"RuinsLevel": {
		'map_bounds': Rect2(-500, -250, 2500, 1150),
		'enemy_weights': [1, 1, 0.3, 1, 0.66, 0.3, 0.2, 0],
		'enemy_density': 7,
		'pace': 1.0,
		'dark': false
	},
	
	"LabyrinthLevel": {
		'map_bounds': Rect2(-315, -260, 2140, 1510),
		'enemy_weights': [1, 0.66, 0.4, 1, 1, 0.2, 0.2, 0.4],
		'enemy_density': 11,
		'pace': 0.6,
		'dark': true
	},
	"Tutorial": {
		'map_bounds': Rect2(-500, -250, 2500, 1150),
		'enemy_weights': [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
		'enemy_density': 1,
		'pace': 0.1,
		'dark': false
	}
}

const upgrades = {
	#SHOTGUN
	'induction_barrel': { #Replaces pellets with piercing flame bullets
		'name': 'Induction Barrel',
		'desc': 'Molten buckshot.',
		'type': 'shotgun',
		'max_stack': 1
	},
	'stacked_shells': { #Increase spread, reload time, and number of projectiles
		'name': 'Stacked Shells',
		'desc': 'The thinking bot\'s sawed-off.',
		'type': 'shotgun',
		'max_stack': 4
	},
	'shock_stock': { #Melee attack stuns
		'name': 'Shock Stock',
		'desc': 'A bayonette made of electrons. Keep your hands on the rubber grips.',
		'type': 'shotgun',
		'max_stack': 2
	},
	'soldering_fingers': { #Pellets are replaced by large projectile that bursts into pellets on inpact
		'name': 'Soldering Fingers',
		'desc': '50%% shot, 50%% slug, 100%% guaranteed to shatter on impact.',
		'type': 'shotgun',
		'max_stack': 1
	},
	'reload_coroutine': { #Decreases reload time and makes shotgun full-auto
		'name': 'Reload Coroutine',
		'desc': 'You didn\'t reload, but your CPU did.',
		'type': 'shotgun',
		'max_stack': 2
	},
	
	#CHAIN
	'precompressed_hydraulics': { #Increase initial charge level
		'name': 'Precompressed Hydraulics',
		'desc': 'Fear the jab.',
		'type': 'chain',
		'max_stack': 2
	},
	'adaptive_wrists': { #Decrease knockback, increase damage
		'name': 'Adaptive Wrists',
		'desc': 'Swing for the kill, not the fences.',
		'type': 'chain',
		'max_stack': 1
	},
	'discharge_flail': { #Attack stuns when charged
		'name': 'Discharge Flail',
		'desc': 'Incapacitating capacitors. Requires charge.',
		'type': 'chain',
		'max_stack': 2
	},
	'vortex_technique': { #Replaces shockwaves with one big piercing shockwave
		'name': 'Vortex Technique',
		'desc': '\"Laminar whipcracks are not possible.\"\n    - An Idiot',
		'type': 'chain',
		'max_stack': 1
	},
	'footwork_scheduler': { #Increase movement speed while charging
		'name': 'Footwork Scheduler',
		'desc': 'Get as close as you\'d like.',
		'type': 'chain',
		'max_stack': 2
	},
	
	#WHEEL
	'advanced_targeting': { #Replace manual aiming with auto targeting
		'name': 'Advanced Targeting',
		'desc': 'Aiming is for pedestrians.',
		'type': 'wheel',
		'max_stack': 1
	},
	'bypassed_muffler': { #Dashing shoots a clound of flame bullets backward
		'name': 'Bypassed Muffler',
		'desc': 'Lethal exhaust.',
		'type': 'wheel',
		'max_stack': 2
	},
	'self-preservation_override': { #Hitting enemies deals velocity-based damage
		'name': 'Self-Preservation Override',
		'desc': 'Become the bullet.',
		'type': 'wheel',
		'max_stack': 1
	},
	'manual_plasma_throttle': { #Pulses can be charged (Chocolate Milk from Isaac)
		'name': 'Manual Plasma Throttle',
		'desc': 'Your pulses, your way.',
		'type': 'wheel',
		'max_stack': 1
	},
	'top_gear': { #Increase max speed, decrease acceleration, preserve speed after dash
		'name': 'Top Gear',
		'desc': 'GAS GAS GAS.',
		'type': 'wheel',
		'max_stack': 1
	},
	
	#FLAME
	'pressurized_hose': { # Increase pressure dropoff and max pressure, decrease start-lag
		'name': 'Pressurized Hose',
		'desc': 'Premature conflagration.',
		'type': 'flame',
		'max_stack': 2
	},
	'optimized_regulator': { #Decrease pressure drop-off and max pressure, decrease movement penalty
		'name': 'Optimized Regulator',
		'desc': 'Slow burn, easier to handle.',
		'type': 'flame',
		'max_stack': 2
	},
	'internal_combustion': { #Increase range and decrease spread, add constant backward recoil
		'name': 'Internal Combustion',
		'desc': 'Handheld rocket engine.',
		'type': 'flame',
		'max_stack': 1,
		'precludes': ['ultrasonic_nozzle']
	},
	'ultrasonic_nozzle': { #Replace flames with gas clouds which all explode after a delay
		'name': 'Ultrasonic Nozzle',
		'desc': 'WARNING: Thermobaric blast resistant visor mandatory.',
		'type': 'flame',
		'max_stack': 1,
		'precludes': ['internal_combustion']
	},
	'aerated_fuel_tanks': { #Increase size of post-mortem explosion
		'name': 'Aerated Fuel Tanks',
		'desc': 'What could go wrong?',
		'type': 'flame',
		'max_stack': 1
	},
	
	#ARCHER
	'vibro-shimmy': { # Allow movement while charging
		'name': 'Vibro-Shimmy',
		'desc': 'Deadly on the battlefield, killer on the dancefloor.',
		'type': 'archer',
		'max_stack': 2
	},
	'half-draw': { # Halves charge time, reduces damage and knockback, removes explosions
		'name': 'Half-Draw',
		'desc': '\"Full auto.\"',
		'type': 'archer',
		'max_stack': 3
	},
	'slobberknocker_protocol': { # Increases beam width and damage
		'name': 'Slobberknocker Protocol',
		'desc': 'Slobberknocker Protocol.',
		'type': 'archer',
		'max_stack': 2
	},
	'scruple_inhibitor': { # Contact damage while in stealth
		'name': 'Scruple Inhibitor',
		'desc': 'Shank \'em good! Right in the oil filter!',
		'type': 'archer',
		'max_stack': 1
	},
	
	#SORCERER
	'elastic_containment': { #Increase orb size, decrease knockback (does not affect terrain collision)
		'name': 'Elastic Containment',
		'desc': 'Less Sol, more Betelgeuse.',
		'type': 'sorcerer',
		'max_stack': 2
	},
	'parallelized_drones': { #Decrease orb size, add additional orb
		'name': 'Parallelized Drones',
		'desc': 'Divide and conquer.',
		'type': 'sorcerer',
		'max_stack': 2
	},
	'docked_drones': { #Increase orb speed and deceleration, limits orb to short radius around controller 
		'name': 'Docked Drones',
		'desc': 'Tokamak teatherball.',
		'type': 'sorcerer',
		'max_stack': 1
	},
	'precision_handling': { #Orb accelerates toward mouse instead of being smacked, and stops when LMB released
		'name': 'Precision Handling',
		'desc': '\"Quick, the safety inspector\'s coming...\"',
		'type': 'sorcerer',
		'max_stack': 1
	},
	
	#SABER
	'fractured_mind': { #Decrease saber ring knockback, replaces saber ring with a spinning ring of three saber rings
		'name': 'Fractured Mind',
		'desc': 'That\'s a lot of swords.',
		'type': 'saber',
		'max_stack': 1
	},
	'true_focus': { # Triples CWBIDBSC damage, increases dash speed and time dilation, cannot die during dash
		'name': 'True Focus',
		'desc': 'Ten milliseconds, a trillion clock cycles, one strike.',
		'type': 'saber',
		'max_stack': 1
	},
	'overclocked_cooling': { # Faster CWBIDBSC cooldown
		'name': 'Overclocked Cooling',
		'desc': 'Expel both heat and remorse.',
		'type': 'saber',
		'max_stack': 2
	},
	'ricochet_simulation': { # Boost saber ring deflection to level 2
		'name': 'Ricochet Simulation',
		'desc': 'Return to sender.',
		'type': 'saber',
		'max_stack': 1
	},
	'supple_telekinesis': { # Increases durability of saber ring
		'name': 'Supple Telekinesis',
		'desc': 'Better to bend than break.',
		'type': 'saber',
		'max_stack': 1
	},
}

var level_name = "RuinsLevel"
var level = levels[level_name]

var timescale = 1
var target_timescale = 1
var timescale_timer = -1

var swappable = false

var swap_bar
var player
var camera
var transcender
var game_HUD
var ground
var obstacles
var wall
var audio
var player_bullets = []

var out_of_control = false

onready var game_time = 0
var spawn_timer = 0
var enemy_soft_cap
var enemy_count = 1
var enemy_hard_cap = 15
var cur_boss = null

var total_score = 0
var variety_bonus = 1.0
var swap_history = ['merchant']

var kills = 0

var evolution_thresholds = [0, 300, 1000, 2000, 3500, 5000, 999999]
var evolution_level = 1

var player_upgrades = {
	#SHOTGUN
	'induction_barrel': 0,
	'stacked_shells': 0,
	'shock_stock': 0,
	'soldering_fingers': 0,
	'reload_coroutine': 0,
	#CHAIN
	'precompressed_hydraulics': 0,
	'adaptive_wrists': 0,
	'discharge_flail': 0,
	'vortex_technique': 0,
	'footwork_scheduler': 0,
	#WHEEL
	'advanced_targeting': 0,
	'bypassed_muffler': 0,
	'self-preservation_override': 0,
	'manual_plasma_throttle': 0,
	'top_gear': 0,
	#FLAME
	'pressurized_hose': 0,
	'optimized_regulator': 0,
	'internal_combustion': 0,
	'ultrasonic_nozzle': 0,
	'aerated_fuel_tanks': 0,
	#ARCHER
	'vibro-shimmy': 0,
	'half-draw': 0,
	'slobberknocker_protocol': 0,
	'scruple_inhibitor': 0,
	#SORCERER
	'elastic_containment': 0,
	'parallelized_drones': 0,
	'docked_drones': 0,
	'precision_handling': 0,
	#SABER
	'fractured_mind': 0,
	'true_focus': 0,
	'overclocked_cooling': 0,
	'ricochet_simulation': 0,
	'supple_telekinesis': 0
}

func _ready():
	add_child(SFX)

func _process(delta):
	if is_instance_valid(player):
		game_time += delta
		spawn_timer -= delta
		
		if timescale_timer < 0:
			timescale = lerp(timescale, target_timescale, delta*12)
			#audio.pitch_scale = timescale
			Engine.time_scale = timescale
		else:
			timescale_timer -= delta/timescale
		
		if spawn_timer < 0:
			spawn_timer = 1
			enemy_soft_cap = level["enemy_density"]*(1 + game_time*0.01*level['pace']) #pow(1.3, game_time/60)
			if level_name != "Tutorial":
				if randf() < (1 - enemy_count/enemy_soft_cap):
					print("SPAWN (" + str(enemy_count + 1) +")")
					spawn_enemy()
					
		if is_instance_valid(cur_boss):
			if is_point_offscreen(cur_boss.global_position):
				boss_marker.visible = int(game_time*6)%2 == 0
				
				var screen_size = camera_bounds()
				var to_boss = cur_boss.global_position - player.global_position
				var h = screen_size.x/max(abs(to_boss.x), 1)
				var v = screen_size.y/max(abs(to_boss.y), 1)
				
				if h < v:
					boss_marker.position = to_boss*h - Vector2(20*sign(to_boss.x), 0)
				else:
					boss_marker.position = to_boss*v - Vector2(0, 20*sign(to_boss.y))
				
				if to_boss.x > 0:
					if to_boss.y > 0:
						boss_marker.region_rect.position.x = 0
					else:
						boss_marker.region_rect.position.x = 32
				else:
					if to_boss.y > 0:
						boss_marker.region_rect.position.x = 96
					else:
						boss_marker.region_rect.position.x = 64
				
				
			else:
				boss_marker.visible = false
			


func lerp_to_timescale(scale):
	target_timescale = scale
	
func set_timescale(scale, lock_duration = 0):
	timescale = scale
	Engine.time_scale = scale
	timescale_timer = lock_duration
	
func spawn_explosion(pos, source, size = 1, damage = 20, force = 200, delay = 0, show_visual = true):
	var new_explosion = explosion.instance().duplicate()
	new_explosion.global_position = pos
	new_explosion.source = source
	new_explosion.scale = Vector2(size, size)
	new_explosion.damage = damage
	new_explosion.force = force
	new_explosion.delay_timer = delay
	new_explosion.visible = show_visual
	get_node("/root").add_child(new_explosion)
	
func spawn_blood(origin, rot, speed = 500, amount = 20, spread = 5):
	var spray = splatter_particles.instance().duplicate()
	get_node("/root/"+ level_name + "/WorldObjects").add_child(spray)
	spray.global_position = origin
	spray.rotation = rot
	spray.process_material.initial_velocity = speed
	spray.amount = amount
	spray.process_material.spread = spread
	spray.emitting = true
	
func spawn_enemy():
	if not player: return
	
	var spawn_point = random_map_point(true)
	if not spawn_point: return
	
	var spawning_boss = not cur_boss and total_score > evolution_thresholds[evolution_level]
	
	enemy_count += 1
	var new_enemy = choose_weighted(enemies, level['enemy_weights']).instance().duplicate()
	new_enemy.add_to_group("enemy")
	
	if spawning_boss:
		cur_boss = new_enemy
		new_enemy.is_boss = true
		new_enemy.enemy_evolution_level = evolution_level+1
		new_enemy.add_swap_shield(new_enemy.health*(evolution_level*0.5 + 1.5))
		new_enemy.scale = Vector2(1.25, 1.25)
		get_node("/root/"+ level_name +"/Camera2D").add_child(boss_marker)
		
	else:
		var d = game_time/30.0*level["pace"]
		if randf() < (d/(d+4.0)/2.0):
			new_enemy.add_swap_shield(randf()*d*5)

	new_enemy.global_position = spawn_point - Vector2(0, new_enemy.get_node("CollisionShape2D").position.y)
	print("LN " + level_name)
	get_node("/root/"+ level_name +"/WorldObjects/Characters").add_child(new_enemy)
			

func reset():
	save_game_stats()
	
	total_score = 0
	kills = 0
	set_evolution_level(1)
	timescale = 1
	game_time = 0
	spawn_timer = 0
	enemy_count = 1
	swap_history = ['merchant']
	player = null
	boss_marker = load("res://Scenes/BossMarker.tscn").instance()
	
func load_level_props(lv_name):
	level_name = lv_name
	if lv_name != "MainMenu":
		level = levels[lv_name]

func kill():
	swappable = false
	player.die()
	
func set_evolution_level(lv):
	evolution_level = min(lv, 6) #min(evolution_level + value/(200+200.0*int(evolution_level)), 5) 
	game_HUD.get_node("EVLShake").get_node("EVL").set_digit(evolution_level)
	game_HUD.get_node("EVLShake").get_node("EVL").express_hype()
	game_HUD.get_node("EVLShake").set_trauma(evolution_level*2)
	
func update_variety_bonus():
	var cur_name = swap_history[-1]
	if swap_history[-2] == cur_name:
		variety_bonus = 0.8
		return
	
	variety_bonus = 0.9
	var used = [cur_name]
	for i in range(2, min(len(swap_history)+1, 8)):
		if not swap_history[-i] in used:
			used.append(swap_history[-i]) 
			variety_bonus += 0.1
		
func increase_score(value):
	var swap_thresh_reduction = value/33/(1 + game_time/200*level["pace"])
	swap_bar.set_swap_threshold(swap_bar.swap_threshold - swap_thresh_reduction)
		
	total_score += value
	game_HUD.get_node("ScoreDisplay").get_node("Score").score = total_score
	
func save_game_stats():
	Options.high_scores[level_name] = max(Options.high_scores[level_name], total_score)
	Options.max_kills[level_name] = max(Options.max_kills[level_name], kills)
	Options.max_time[level_name] = max(Options.max_time[level_name], game_time)
	Options.max_EVL[level_name] = max(Options.max_EVL[level_name], evolution_level)
	Options.saveSettings()
	
func signal_player_swap():
	emit_signal("on_swap")
	
func random_map_point(off_screen_required = false):
	var i = 0
	var bounds = level['map_bounds']
	while(i < 1000):
		i += 1
		var point = Vector2(bounds.position.x + randf()*bounds.size.x, bounds.position.y + randf()*bounds.size.y)
		if is_point_in_bounds(point) and (not off_screen_required or is_point_offscreen(point, 20)):
			return point
		
	
func is_point_in_bounds(global_point):
	var ground_points = ground.world_to_map(global_point)
	var marble_point = wall.world_to_map(global_point)
	var obstacles_point = obstacles.world_to_map(global_point)
	
	return ground_points in ground.get_used_cells() and not marble_point in wall.get_used_cells() and not obstacles_point in obstacles.get_used_cells()
	
func is_point_offscreen(point, margin = 0):
	var bounds = camera_bounds()
	var from_camera = point - camera.global_position
	return abs(from_camera.x) > bounds.x + margin or abs(from_camera.y) > bounds.y + margin
	
func camera_bounds():
	var ctrans = camera.get_canvas_transform()
	var view_size = camera.get_viewport_rect().size / ctrans.get_scale()
	return view_size/2
	
static func choose_weighted(values, weights):
	var cumu_weights = [weights[0]]
	for i in range(1, len(weights)):
		cumu_weights.append(weights[i] + cumu_weights[i-1])
	
	var rand = randf()*cumu_weights[-1]
	for i in range(cumu_weights.size()):
		if rand < cumu_weights[i]:
			return values[i]
