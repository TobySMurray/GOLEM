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
	Enemy.EnemyType.SHOTGUN: shotgun_bot,
	Enemy.EnemyType.WHEEL: wheel_bot,
	Enemy.EnemyType.ARCHER: archer_bot,
	Enemy.EnemyType.CHAIN: chain_bot,
	Enemy.EnemyType.FLAME: flame_bot, 
	Enemy.EnemyType.EXTERMINATOR: exterminator_bot,
	Enemy.EnemyType.SORCERER: sorcerer_bot,
	Enemy.EnemyType.SABER: saber_bot
}

onready var swap_unlock_sound = load("res://Sounds/SoundEffects/Wub1.wav")

signal on_swap
signal on_level_ready

var arcade_mode = false

var world = null
var level_name = "MainMenu"
var level = Levels.level_data[level_name]
var fixed_map = null

var projectiles_node

var timescale = 1
var target_timescale = 1
var timescale_timer = -1

var player
var true_player

var player_hidden = true
var player_switch_timer = 0

var can_swap = false
var swapping = false
var swap_timer = 0

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

var game_time = 0
var level_time = 0

var spawn_timer = 0
var enemy_soft_cap
var enemy_count = 1
var enemy_hard_cap = 15
var cur_boss = null
var enemy_drought_bailout_available = true

var score = 0
var variety_bonus = 1.0
var swap_history = [Enemy.EnemyType.UNKNOWN]

var hyperdeath_mode = false
var hyperdeath_start_time = 0

var kills = 0

var evolution_level = 1
var init_evolution_level = 1
var evolution_thresholds = [0, 300, 1000, 2000, 3500, 5000, 999999]

var player_upgrades = {
	#SHOTGUN
	'induction_barrel': 0,
	'stacked_shells': 0,
	'shock_stock': 0,
	'soldering_fingers': 1,
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
	'triple_nock' : 1,
	'bomb_loader' : 0,
	'tazer_bomb' : 0,
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
	randomize()
	projectiles_node = get_node('/root')
	
func _process(delta):
	if timescale_timer < 0:
		timescale = lerp(timescale, target_timescale, delta*12)
		#audio.pitch_scale = timescale
		Engine.time_scale = timescale
	else:
		timescale_timer -= delta/timescale
		
	game_time += delta	
	if is_instance_valid(true_player):
		level_time += delta
		spawn_timer -= delta
		
		if spawn_timer < 0 and level['enemy_density'] > 0:
			spawn_timer = 1
			enemy_soft_cap = level["enemy_density"]*(1 + level_time*0.01*level['pace']) #pow(1.3, level_time/60)
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
			
func start_game(mode, init_level, fixed_map_ = null, skip_transition = false):
		if mode == 'arcade':
			arcade_mode = true
			
		elif mode == 'campaign':
			arcade_mode = false
			
		else:
			print('ERROR: Invalid gamemode (' + mode + ')')
			return
		
		level_name = init_level
		level = Levels.level_data[init_level]
		fixed_map = fixed_map_
		
		game_time = 0
		init_evolution_level = 1
		
		for key in player_upgrades:
			#player_upgrades[key] = 0
			pass
		
		if not world:
			scene_transition.fade_out_to_scene('res://Scenes/World.tscn', 0 if skip_transition else 0.5)
		else:
			scene_transition.fade_out_and_restart(0 if skip_transition else 0.5)
		
func on_world_loaded(world_ = world):
	world = world_
	projectiles_node = world.objects_node
	
	camera = world.camera
	game_HUD = camera.get_node('CanvasLayer/ScoreDisplay')
	boss_marker = load("res://Scenes/BossMarker.tscn").instance()
	
	camera.add_child(boss_marker)
	boss_marker.visible = false
		
	world.load_level(level_name, fixed_map)
	
					
func start_level():
	if level_name != 'TestLevel':
		swap_bar.enabled = true
	else:
		swap_bar.enabled = true
		
	world.init_player.toggle_playerhood(true)
		
	play_level_bgm()
		
	camera.set_anchor(world.init_player)
	camera.get_node('CanvasLayer/DeathScreen').visible = false
	
	score = 0
	kills = 0
	set_timescale(1)
	target_timescale = 1
	set_evolution_level(init_evolution_level)
	level_time = 0
	spawn_timer = 0
	enemy_count = 1
	cur_boss = null
	
	swap_bar.visible = true
	swap_bar.reset()
	swap_bar.set_swap_threshold(1)
	
	swap_history = [Enemy.EnemyType.UNKNOWN]
	hyperdeath_mode = false
	wall_foreground = null
	
	scene_transition.fade_in()
	emit_signal('on_level_ready')
	
func game_over():
	can_swap = false
	lerp_to_timescale(0.1)
	swap_bar.visible = false
	
	if level_name != 'TestLevel':
		save_game_stats()
	
	var death_screen = camera.get_node('CanvasLayer/DeathScreen')
	var final_score_label = death_screen.get_node('ScoreLabel')
	var high_score_label =death_screen.get_node('HighScore')
	
	if level_name != 'TestLevel':
		final_score_label.set_text("Score: " + str(GameManager.score))
		high_score_label.set_text("High Score: " + str(Options.high_scores[GameManager.level_name]))
		if Options.high_scores[GameManager.level_name] < GameManager.score:
			final_score_label.set("custom_colors/font_color", ("e6e72a"))
			high_score_label.set_text("High Score: " + str(GameManager.score))
	death_screen.popup()
	
		
func play_level_bgm(level_name_ = level_name):
	var music = load('res://Sounds/Music/' + Levels.level_data[level_name_]['music'])
	if BGM.stream != music:
		BGM.stream = music
		BGM.play()
		
		
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
	world.objects_node.add_child(spray)
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
		if is_instance_valid(enemy) and not enemy.is_miniboss:
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
		if randf() < (level_time - hyperdeath_start_time) / (level_time - hyperdeath_start_time + 600):
			boss_lv = int(1 + randf()*(level_time - hyperdeath_start_time)/60)
	else:
		if allow_boss and not is_instance_valid(cur_boss) and score > evolution_thresholds[evolution_level]:
			boss_lv = evolution_level + 1
		
	spawn_enemy(Util.choose_weighted(enemy_scenes.keys(), level['enemy_weights']), spawn_point, boss_lv)
	
func spawn_enemy(type, spawn_point = level['map_bounds'], EVL = 0):
	if typeof(spawn_point) != TYPE_VECTOR2:
		spawn_point = random_spawn_point(type, spawn_point, true)
		if not spawn_point:
			print("SPAWN FAILED")
			return null
		
	var new_enemy = enemy_scenes[type].instance().duplicate()
	new_enemy.add_to_group("enemy")
	
	if EVL > 0:
		new_enemy.is_miniboss = true
		new_enemy.enemy_evolution_level = EVL
		new_enemy.add_swap_shield(new_enemy.health*(EVL*0.5 + 1.0))
		new_enemy.scale = Vector2(1.25, 1.25)
		if not hyperdeath_mode:
			cur_boss = new_enemy
		
	else:
		var d = level_time/30.0*level["pace"] - 2
		if randf() < (d/(d+4.0)/2.0):
			new_enemy.add_swap_shield(randf()*d*5)
			
	enemy_count += 1
	enemies.append(new_enemy)
	new_enemy.global_position = spawn_point - Vector2(0, new_enemy.get_node("CollisionShape2D").position.y)
	world.objects_node.add_child(new_enemy)
	return new_enemy
	
	
func toggle_swap(state):
	if state == true and not can_swap:
		return
		
	swapping = state
	swap_timer = 1.5
	swap_bar.sparks.emitting = false
	swap_bar.rising_audio.stop()
	
	if(swapping):
		lerp_to_timescale(0.1)
		world.blood_moon.slow_audio.play()
		world.blood_moon.moon_visible = true
		#choose_swap_target()
	else:
		camera.lerp_zoom(1)
		lerp_to_timescale(1)
		
		world.blood_moon.stopped_audio.stop()
		world.blood_moon.slow_audio.stop()
		world.blood_moon.speed_audio.play()
		world.blood_moon.moon_visible = false
		world.blood_moon.selected_enemy = null
		world.transcender.clear_transcender()
	
	
func choose_swap_target(delta):
	if is_instance_valid(true_player):
		var swap_cursor = world.blood_moon
		swap_cursor.global_position = true_player.get_global_mouse_position()
		
		camera.lerp_zoom(1 + (swap_bar.control_timer - swap_bar.swap_threshold)/swap_bar.max_control_time)
		
		swap_timer -= delta/max(timescale, 0.01)
		if swap_timer < 0:
			swap_bar.set_swap_threshold(swap_bar.swap_threshold + delta/max(timescale, 0.01))
			if not swap_bar.sparks.emitting:
				swap_bar.sparks.emitting = true
				swap_bar.rising_audio.play()

		if can_swap:
			if Input.is_action_just_released("swap"):
				if is_instance_valid(swap_cursor.selected_enemy):
					true_player.toggle_playerhood(false)
					swap_cursor.selected_enemy.toggle_playerhood(true)
					swap_bar.reset()
					
				if is_instance_valid(swap_cursor.selected_enemy) or not true_player.dead:
					toggle_swap(false)
			else:
				swap_cursor.draw_transcender(true_player.global_position)
				
		else:
			toggle_swap(false)
			
	
func on_swap(new_player):
	if true_player:
		if player != true_player:
			true_player.toggle_enhancement(false)
			player = true_player
			
		set_player_after_delay(new_player, 1)
	else:
		true_player = new_player
		player = new_player
	
	player_hidden = false
	camera.anchor = new_player
	camera.offset = Vector2.ZERO
	swap_history.append(new_player.enemy_type)
	update_variety_bonus()
	enemy_drought_bailout_available = true
	Options.enemy_swaps[str(new_player.enemy_type)] += 1
	emit_signal("on_swap")
	
			
func give_player_random_upgrade(type = Enemy.EnemyType.UNKNOWN):
	if type == Enemy.EnemyType.UNKNOWN: 
		type = Enemy.EnemyType.values()[int(randf()*8)]
	
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
	

func kill():
	can_swap = false
	player.die()
	
func set_evolution_level(lv):
	evolution_level = min(lv, 6) #min(evolution_level + value/(200+200.0*int(evolution_level)), 5) 
	game_HUD.get_node("EVLShake").get_node("EVL").set_digit(evolution_level)
	game_HUD.get_node("EVLShake").get_node("EVL").express_hype()
	game_HUD.get_node("EVLShake").set_trauma(evolution_level*2)
	
	if lv >= 6 and not hyperdeath_mode:
		hyperdeath_mode = true
		hyperdeath_start_time = level_time
	
func update_boss_marker():
	if dist_offscreen(cur_boss.global_position) > 0 and cur_boss.health > 0:
		boss_marker.visible = int(level_time*6)%2 == 0
		
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
	print(swap_history)
	var cur_type = swap_history[-1]
	if swap_history[-2] == cur_type:
		variety_bonus = 0.8
		return
	
	variety_bonus = 0.9
	var used = [cur_type]
	for i in range(2, min(len(swap_history)+1, 8)):
		if not swap_history[-i] in used:
			used.append(swap_history[-i]) 
			variety_bonus += 0.1
		
func increase_score(value):
	var swap_thresh_reduction = value/33/(1 + level_time/250*level["pace"])
	swap_bar.set_swap_threshold(swap_bar.swap_threshold - swap_thresh_reduction)
		
	score += value
	game_HUD.get_node("ScoreDisplay").get_node("Score").score = score
	
func enemy_drought_bailout():
	enemy_drought_bailout_available = false
	var drought = true
	var candidate = null
	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy != player and not enemy.is_miniboss and ((abs(enemy.global_position.x - player.global_position.x) < 300 and abs(enemy.global_position.y - player.global_position.y) < 200) or dist_offscreen(enemy.global_position) < 0):
				drought = false
				candidate = enemy
				break
				
			if not candidate and enemy != player and not enemy.is_miniboss and dist_offscreen(enemy.global_position) > 20:
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
	Options.high_scores[level_name] = max(Options.high_scores[level_name], score)
	Options.max_kills[level_name] = max(Options.max_kills[level_name], kills)
	Options.max_time[level_name] = max(Options.max_time[level_name], level_time)
	Options.max_EVL[level_name] = max(Options.max_EVL[level_name], evolution_level)
	Options.saveSettings()
	
func random_spawn_point(enemy_type, bounds = null, off_screen_required = false):
	var camera_rect = camera_rect() if off_screen_required else Rect2()
	var valid_zones = []
	var weights = []
	for zone in world.spawn_zones[enemy_type]:
		if not camera_rect.encloses(zone):
			if not bounds:
				valid_zones.append(zone)
				weights.append(zone.get_area() - zone.clip(camera_rect).get_area())
				
			elif bounds.intersects(zone):
				var clipped_zone = zone.clip(bounds)
				valid_zones.append(clipped_zone)
				weights.append(clipped_zone.get_area() - clipped_zone.clip(camera_rect).get_area())
	
	var valid_zone_exists = false
	for weight in weights:
		if weight > 0:
			valid_zone_exists = true
			
	if not valid_zone_exists:
		return false 
		
	var rect = Util.choose_weighted(valid_zones, weights)
	
	if rect.intersects(camera_rect):
		var dif_rects = Util.rect_difference(rect, camera_rect)
		weights = []
		for subrect in dif_rects:
			weights.append(subrect.get_area())
		rect = Util.choose_weighted(dif_rects, weights)
		
	return rect.position + Vector2(randf()*rect.size.x, randf()*rect.size.y)
			
		
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
	
func camera_rect():
	var size = camera_bounds()*2
	var center = camera.global_position + camera.offset
	return Rect2(center - size/2, size)
	
func camera_bounds():
	var ctrans = camera.get_canvas_transform()
	var view_size = camera.get_viewport_rect().size / ctrans.get_scale()
	return view_size/2

