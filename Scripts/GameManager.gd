extends Node

onready var explosion = load("res://Scenes/Explosion.tscn")
onready var boss_marker = load("res://Scenes/BossMarker.tscn").instance()
onready var splatter_particles = load("res://Scenes/Particles/SplatterParticles.tscn")
onready var upgrade_popup = load('res://Scenes/ItemPopup.tscn').instance()

onready var shotgun_bot = load("res://Scenes/ShotgunnerBot.tscn")
onready var wheel_bot = load("res://Scenes/WheelBot.tscn")
onready var archer_bot = load("res://Scenes/ArcherBot.tscn")
onready var chain_bot = load("res://Scenes/ChainBot.tscn")
onready var flame_bot = load("res://Scenes/FlamethrowerBot.tscn")
onready var exterminator_bot = load("res://Scenes/ExterminatorBot.tscn")
onready var sorcerer_bot = load("res://Scenes/SorcererBot.tscn")
onready var saber_bot = load("res://Scenes/SaberBot.tscn")

onready var scene_transition = $SceneTransition.get_node('TransitionRect')
onready var attack_cooldown_SFX = $AttackCooldownSFX
onready var special_cooldown_SFX = $SpecialCooldownSFX2
onready var BGM = $BGM

onready var viewport = get_viewport()

onready var enemy_scenes = {
	'shotgun': shotgun_bot,
	'wheel': wheel_bot,
	'archer': archer_bot,
	'chain': chain_bot,
	'flame': flame_bot, 
	'exterminator': exterminator_bot,
	'sorcerer': sorcerer_bot,
	'saber': saber_bot
}

onready var swap_unlock_sound = load("res://Sounds/SoundEffects/Wub1.wav")

signal on_swap
signal on_level_ready

const levels = {
	'MainMenu': {
		'dark': false,
		'music': 'cuuuu b3.wav'
	},
	
	"TestLevel": {
		'map_bounds': Rect2(-250, -250, 500, 500),
		'enemy_weights': [1, 1, 0.3, 1, 0.66, 0.3, 0.2, 0],
		'enemy_density': 0,
		'pace': 0,
		'dark': false,
		'music': 'cuuuu b3.wav',
		'scene_name': 'TestRoom.tscn'
	},
		
	"SkyRuins": {
		'map_bounds': Rect2(-500, -250, 2500, 1150),
		'enemy_weights': [1, 1, 0.3, 1, 0.66, 0.3, 0.2, 0],
		'enemy_density': 7,
		'pace': 0.9,
		'dark': false,
		'music': 'melon b3.wav',
		'scene_name': 'SkyRuins1.tscn'
	},
	
	"Labyrinth": {
		'map_bounds': Rect2(-315, -260, 2140, 1510),
		'enemy_weights': [1, 0.66, 0.4, 1, 1, 0.2, 0.2, 0.4],
		'enemy_density': 12,
		'pace': 0.6,
		'dark': true,
		'music': 'cantaloupe b3.wav',
		'scene_name': 'Labyrinth1.tscn'
	},
	"Desert": {
		'map_bounds': Rect2(-1050, -700, 2100, 1700),
		'enemy_weights': [1, 1, 0.3, 1, 0.66, 0.3, 0.2, 0],
		'enemy_density': 12,
		'pace': 0.9,
		'dark': false,
		'music': 'melon b3.wav',
		'scene_name': 'Desert1.tscn'
	},
	"Tutorial": {
		'map_bounds': Rect2(-500, -250, 2500, 1150),
		'enemy_weights': [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
		'enemy_density': 1,
		'pace': 0.1,
		'dark': false
	}
}

var level_name = "MainMenu"
var level = levels[level_name]
var projectiles_node

var timescale = 1
var target_timescale = 1
var timescale_timer = -1

var player
var true_player
var player_hidden = true
var player_switch_timer = 0

var swappable = false

var swap_bar
var camera
var transcender
var game_HUD
var ground
var obstacles
var wall
var wall_foreground = null
var audio
var player_bullets = []
var enemies = []

var out_of_control = false

onready var game_time = 0
var spawn_timer = 0
var enemy_soft_cap
var enemy_count = 1
var enemy_hard_cap = 15
var cur_boss = null
var enemy_drought_bailout_available = true

var total_score = 0
var variety_bonus = 1.0
var swap_history = ['merchant']

var hyperdeath_mode = false
var hyperdeath_start_time = 0

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
	#EXTERMINATOR
	'improvised_projectiles': 0,
	'high-energy_orbit': 0,
	'impulse_accelerator': 0,
	'exposed_coils': 0,
	'bulwark_mode': 0,
	'particulate_screen': 0,
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
	projectiles_node = get_node('/root')
	
func _process(delta):
	if timescale_timer < 0:
		timescale = lerp(timescale, target_timescale, delta*12)
		#audio.pitch_scale = timescale
		Engine.time_scale = timescale
	else:
		timescale_timer -= delta/timescale
			
	if is_instance_valid(true_player):
		game_time += delta
		spawn_timer -= delta
		
		if spawn_timer < 0 and level['enemy_density'] > 0:
			spawn_timer = 1
			enemy_soft_cap = level["enemy_density"]*(1 + game_time*0.01*level['pace']) #pow(1.3, game_time/60)
			if randf() < (1 - enemy_count/enemy_soft_cap):
				print("SPAWN (" + str(enemy_count + 1) +")")
				spawn_random_enemy()
					
		if is_instance_valid(cur_boss):
			update_boss_marker()
			
		if enemy_drought_bailout_available and swap_bar.control_timer > 17:
			enemy_drought_bailout()
			
	if player != true_player:
		player_switch_timer -= delta
		if player_switch_timer < 0:
			if is_instance_valid(player):
				player.toggle_enhancement(false)
			player = true_player
			
					
func reset():
	if level_name != 'TestLevel':
		save_game_stats()
		swap_bar.enabled = true
	else:
		swap_bar.enabled = false
	
	total_score = 0
	kills = 0
	set_evolution_level(1)
	set_timescale(1)
	target_timescale = 1
	game_time = 0
	spawn_timer = 0
	enemy_count = 1
	swap_history = ['merchant']
	player = null
	true_player = null
	hyperdeath_mode = false
	wall_foreground = null
	
	boss_marker = load("res://Scenes/BossMarker.tscn").instance()
	get_node("/root/"+ level_name +"/Camera2D").add_child(boss_marker)
	boss_marker.visible = false
	
	for key in player_upgrades:
	#	if randf() < 0.75: player_upgrades[key] += 1
		player_upgrades[key] = 0
		pass
		
		
func lerp_to_timescale(scale):
	target_timescale = scale
	
func set_timescale(scale, lock_duration = 0):
	timescale = scale
	Engine.time_scale = scale
	timescale_timer = lock_duration
	
func set_player_after_delay(new_player, delay):
	true_player = new_player
	player_switch_timer = delay
	
func spawn_explosion(pos, source, size = 1, damage = 20, force = 200, delay = 0, show_visual = true):
	var new_explosion = explosion.instance().duplicate()
	new_explosion.global_position = pos
	new_explosion.source = source
	new_explosion.scale = Vector2(size, size)
	new_explosion.damage = damage
	new_explosion.force = force
	new_explosion.delay_timer = delay
	new_explosion.visible = show_visual
	projectiles_node.add_child(new_explosion)
	
func spawn_blood(origin, rot, speed = 500, amount = 20, spread = 5):
	if amount < 1:
		return
		
	var spray = splatter_particles.instance().duplicate()
	get_node("/root/"+ level_name + "/WorldObjects").add_child(spray)
	spray.global_position = origin
	spray.rotation = rot
	spray.process_material.initial_velocity = speed
	spray.amount = amount
	spray.process_material.spread = spread
	spray.emitting = true
	
func spawn_random_enemy(allow_boss = true, spawn_point = level['map_bounds']):
	Util.remove_invalid(enemies)
	var spawn_near_player = true
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_boss:
			var dist = dist_offscreen(enemy.global_position)
			if dist < 50:
				if randf() + dist/100 < 0.5:
					spawn_near_player = false
					break
				
	if spawn_near_player:
		print("Spawning near player")
		var bounds = camera_bounds()*1.5 if swap_bar.control_timer < 15 else camera_bounds()*1.2
		var origin = Vector2(camera.position.x + camera.offset.x - bounds.x, camera.position.y + camera.offset.y - bounds.y)
		spawn_point = Rect2(origin.x, origin.y, bounds.x*2, bounds.y*2)
		
	var boss_lv = 0
	if hyperdeath_mode:
		if randf() < (game_time - hyperdeath_start_time) / (game_time - hyperdeath_start_time + 600):
			boss_lv = int(1 + randf()*(game_time - hyperdeath_start_time)/60)
	else:
		if allow_boss and not is_instance_valid(cur_boss) and total_score > evolution_thresholds[evolution_level]:
			boss_lv = evolution_level + 1
		
	spawn_enemy(choose_weighted(enemy_scenes.keys(), level['enemy_weights']), spawn_point, boss_lv)
	
func spawn_enemy(type, spawn_point = level['map_bounds'], EVL = 0):
	if typeof(spawn_point) != TYPE_VECTOR2:
		spawn_point = random_map_point(spawn_point, true)
		if not spawn_point:
			print("SPAWN FAILED")
			return null
		
	var new_enemy = enemy_scenes[type].instance().duplicate()
	new_enemy.add_to_group("enemy")
	
	if EVL > 0:
		new_enemy.is_boss = true
		new_enemy.enemy_evolution_level = EVL
		new_enemy.add_swap_shield(new_enemy.health*(EVL*0.5 + 1.0))
		new_enemy.scale = Vector2(1.25, 1.25)
		if not hyperdeath_mode:
			cur_boss = new_enemy
		
	else:
		var d = game_time/30.0*level["pace"] - 2
		if randf() < (d/(d+4.0)/2.0):
			new_enemy.add_swap_shield(randf()*d*5)
			
	enemy_count += 1
	enemies.append(new_enemy)
	new_enemy.global_position = spawn_point - Vector2(0, new_enemy.get_node("CollisionShape2D").position.y)
	get_node("/root/"+ level_name +"/WorldObjects/Characters").add_child(new_enemy)
	return new_enemy
	
func on_swap(new_player):
	if player != true_player:
		true_player.toggle_enhancement(false)
		player = true_player
		
	set_player_after_delay(new_player, 1)
	
	player_hidden = false
	camera.anchor = new_player
	camera.offset = Vector2.ZERO
	camera.lerp_zoom(1)
	swap_history.append(new_player.enemy_type)
	update_variety_bonus()
	enemy_drought_bailout_available = true
	Options.enemy_swaps[new_player.enemy_type] += 1
	emit_signal("on_swap")
	
			
func give_player_random_upgrade(type = ''):
	if type == '': 
		type = ['shotgun', 'chain', 'wheel', 'flame', 'archer', 'exterminator', 'sorcerer', 'saber'][int(randf()*8)]
	
	var upgrade_pool = []
	for upgrade in Upgrades.upgrades.keys():
		if Upgrades.upgrades[upgrade]['type'] == type:
			upgrade_pool.append(upgrade)
			
	for upgrade in player_upgrades.keys():
		if player_upgrades[upgrade] > 0 and 'precludes' in Upgrades.upgrades[upgrade]:
			for precluded in Upgrades.upgrades[upgrade]['precludes']:
				upgrade_pool.erase(precluded)
				
		if player_upgrades[upgrade] >= Upgrades.upgrades[upgrade]['max_stack']:
			upgrade_pool.erase(upgrade)
	
	if not upgrade_pool.empty():		
		var upgrade = upgrade_pool[int(randf()*len(upgrade_pool))]
		give_player_upgrade(upgrade)
	
func give_player_upgrade(upgrade):
	print("New upgrade: "+ upgrade)
	player_upgrades[upgrade] += 1
	
	var popup = upgrade_popup.duplicate()
	camera.get_node('CanvasLayer').add_child(popup)
	popup.set_upgrade(upgrade)
	popup.show()
	
func on_level_loaded(lv_name):
	level_name = lv_name
	level = levels[lv_name]
	
	var music = load('res://Sounds/Music/' + level['music'])
	if BGM.stream != music:
		BGM.stream = load('res://Sounds/Music/' + level['music'])
		BGM.play()
	
	if lv_name != "MainMenu":
		projectiles_node = get_node('/root/' + level_name + '/Projectiles')
		if not projectiles_node:
			print("ERROR: No \"Projectiles\" node found in level heirarchy")
			projectiles_node = get_node('/root')
			
		reset()
		
	scene_transition.fade_in()
	emit_signal('on_level_ready')

func kill():
	swappable = false
	player.die()
	
func set_evolution_level(lv):
	evolution_level = min(lv, 6) #min(evolution_level + value/(200+200.0*int(evolution_level)), 5) 
	game_HUD.get_node("EVLShake").get_node("EVL").set_digit(evolution_level)
	game_HUD.get_node("EVLShake").get_node("EVL").express_hype()
	game_HUD.get_node("EVLShake").set_trauma(evolution_level*2)
	
	if lv >= 6 and not hyperdeath_mode:
		hyperdeath_mode = true
		hyperdeath_start_time = game_time
	
func update_boss_marker():
	if dist_offscreen(cur_boss.global_position) > 0 and cur_boss.health > 0:
		boss_marker.visible = int(game_time*6)%2 == 0
		
		var screen_size = camera_bounds()
		var to_boss = cur_boss.global_position - true_player.global_position
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
	var swap_thresh_reduction = value/33/(1 + game_time/250*level["pace"])
	swap_bar.set_swap_threshold(swap_bar.swap_threshold - swap_thresh_reduction)
		
	total_score += value
	game_HUD.get_node("ScoreDisplay").get_node("Score").score = total_score
	
func enemy_drought_bailout():
	enemy_drought_bailout_available = false
	var drought = true
	var candidate = null
	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy != player and not enemy.is_boss and ((abs(enemy.global_position.x - player.global_position.x) < 300 and abs(enemy.global_position.y - player.global_position.y) < 200) or dist_offscreen(enemy.global_position) < 0):
				drought = false
				candidate = enemy
				break
				
			if not candidate and enemy != player and not enemy.is_boss and dist_offscreen(enemy.global_position) > 20:
				candidate = enemy
			
	if drought:
		var camera_bounds = camera_bounds()
		var placement_bounds = Rect2(camera.global_position.x + camera.offset.x, camera.global_position.y + camera.offset.y, camera_bounds.x*1.2, camera_bounds.y*1.4)
		var spawn_needed = not candidate
		if not candidate:
			candidate = spawn_random_enemy(false)
			if candidate:
				candidate.swap_shield_health = 0
				candidate.update_swap_shield()
			
		var point = random_map_point(placement_bounds, true)	
		if not candidate or not point:
			enemy_drought_bailout_available = true
			print('EDB Failure!')
		else:
			candidate.global_position = point
			print('EDB initiated: Deployed ' + candidate.name + ' at ' + str(candidate.global_position) + (' [Emergency spawn required]' if spawn_needed else ''))
	else:
		print('Bailout unnecessary due to ' + candidate.name + ' at ' + str(candidate.global_position))
			
	
func save_game_stats():
	Options.high_scores[level_name] = max(Options.high_scores[level_name], total_score)
	Options.max_kills[level_name] = max(Options.max_kills[level_name], kills)
	Options.max_time[level_name] = max(Options.max_time[level_name], game_time)
	Options.max_EVL[level_name] = max(Options.max_EVL[level_name], evolution_level)
	Options.saveSettings()
		
func random_map_point(bounds = level['map_bounds'], off_screen_required = false):
	var i = 0
	while(i < 100):
		i += 1
		var point = Vector2(bounds.position.x + randf()*bounds.size.x, bounds.position.y + randf()*bounds.size.y)
		if is_point_in_bounds(point) and (not off_screen_required or dist_offscreen(point) > 20):
			return point
		
func is_point_in_bounds(global_point):
	var ground_points = ground.world_to_map(global_point)
	var marble_point = wall.world_to_map(global_point)
	var obstacles_point = obstacles.world_to_map(global_point)
	if wall_foreground:
		var foreground_point = wall_foreground.world_to_map(global_point)
		return ground_points in ground.get_used_cells() and not marble_point in wall.get_used_cells() and not obstacles_point in obstacles.get_used_cells() and not wall_foreground in wall_foreground.get_used_cells()
	
	return ground_points in ground.get_used_cells() and not marble_point in wall.get_used_cells() and not obstacles_point in obstacles.get_used_cells()
	
func dist_offscreen(point):
	var bounds = camera_bounds()
	var from_camera = point - camera.global_position - camera.offset
	return max(abs(from_camera.x) - bounds.x, abs(from_camera.y) - bounds.y)
	
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
