extends Node

onready var explosion = load("res://Scenes/Explosion.tscn")
onready var boss_marker = load("res://Scenes/BossMarker.tscn").instance()

onready var shotgun_bot = load("res://Scenes/ShotgunnerBot.tscn")
onready var wheel_bot = load("res://Scenes/WheelBot.tscn")
onready var archer_bot = load("res://Scenes/ArcherBot.tscn")
onready var chain_bot = load("res://Scenes/ChainBot.tscn")
onready var flame_bot = load("res://Scenes/FlamethrowerBot.tscn")
onready var exterminator_bot = load("res://Scenes/ExterminatorBot.tscn")
onready var sorcerer_bot = load("res://Scenes/SorcererBot.tscn")
onready var viewport = get_viewport()

onready var enemies = [shotgun_bot, wheel_bot, archer_bot, chain_bot, flame_bot, exterminator_bot, sorcerer_bot]
var enemy_weights = [1, 1, 0.3, 1, 0.66, 0.3, 0.2]

onready var SFX = AudioStreamPlayer.new()
onready var swap_unlock_sound = load("res://Sounds/SoundEffects/Wub1.wav")




var timescale = 1
var target_timescale = 1

var swappable = false

var swap_bar
var player
var camera
var transcender
var total_score = 0
var score_display
var ground
var obstacles
var wall
var audio
var player_bullets = []

var out_of_control = false

onready var game_time = 0
var spawn_timer = 0
var enemy_soft_cap
var enemy_count = 7
var enemy_hard_cap = 15
var cur_boss = null

var evolution_thresholds = [0, 300, 1000, 2000, 3500, 5000, 999999]
var evolution_level = 1

func _ready():
	add_child(SFX)

func _process(delta):
	if player:
		game_time += delta
		spawn_timer -= delta
		timescale = lerp(timescale, target_timescale, delta*12)
		audio.pitch_scale = timescale
		Engine.time_scale =  timescale
		
		if spawn_timer < 0:
			spawn_timer = 1
			enemy_soft_cap = 7 + game_time/15 #pow(1.3, game_time/60)
			
			if randf() < (1 - enemy_count/enemy_soft_cap):
				print("SPAWN (" + str(enemy_count + 1) +")")
				spawn_enemy()
				
		if cur_boss:
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
	
func spawn_explosion(pos, source, size = 1, damage = 20, force = 200, delay = 0):
	var new_explosion = explosion.instance().duplicate()
	new_explosion.global_position = pos
	new_explosion.source = source
	new_explosion.scale = Vector2(size, size)
	new_explosion.damage = damage
	new_explosion.force = force
	new_explosion.delay_timer = delay
	get_node("/root").add_child(new_explosion)
	
func spawn_enemy():
	if not player: return
	
	var spawn_point = random_map_point(true)
	if not spawn_point: return
	
	enemy_count += 1
	var new_enemy = choose_weighted(enemies, enemy_weights).instance().duplicate()
	new_enemy.add_to_group("enemy")
	
	if not cur_boss and total_score > evolution_thresholds[evolution_level] and not new_enemy.get_script() == enemies[2].get_script():
		cur_boss = new_enemy
		new_enemy.is_boss = true
		new_enemy.enemy_evolution_level = evolution_level+1
		new_enemy.add_swap_shield(new_enemy.health*(evolution_level*0.5 + 1.5))
		new_enemy.scale = Vector2(1.25, 1.25)
		get_node("/root/MainLevel/Camera2D").add_child(boss_marker)
		
	else:
		var d = game_time/30
		if randf() < (d/(d+3)/2):
			new_enemy.add_swap_shield(randf()*d*5)

	new_enemy.global_position = spawn_point - Vector2(0, new_enemy.get_node("CollisionShape2D").position.y)
	get_node("/root/MainLevel/WorldObjects/Characters").add_child(new_enemy)
			

func reset():
	total_score = 0
	set_evolution_level(1)
	timescale = 1
	game_time = 0
	spawn_timer = 0
	enemy_count = 7
	player = null
	boss_marker = load("res://Scenes/BossMarker.tscn").instance()

func kill():
	swappable = false
	player.die()
	
func set_evolution_level(lv):
	evolution_level = min(lv, 6) #min(evolution_level + value/(200+200.0*int(evolution_level)), 5) 
	score_display.get_node("EVL").text = str(int(evolution_level))
	score_display.get_node("EVL").modulate = [Color.green, Color.yellow, Color.orange, Color.red, Color(1, 0, 0.5), Color(1, 0.2, 0.6)][int(evolution_level-1)]
	score_display.get_node("EVL").set_trauma(evolution_level-1)

func increase_score(value):
	if swap_bar.swap_threshold == 0:
		value *= 1.5
	else:
		var swap_thresh_reduction = value/25/(1 + game_time/250)
		swap_bar.set_swap_threshold(swap_bar.swap_threshold - swap_thresh_reduction)
		
	total_score += value
	score_display.get_node("Score").score = total_score
	
func random_map_point(off_screen_required = false):
	var i = 0
	while(i < 1000):
		i += 1
		var point = Vector2(-500 + randf()*2500, -250 + randf()*1150)
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
