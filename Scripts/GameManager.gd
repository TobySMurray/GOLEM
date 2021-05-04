extends Node

onready var explosion = load("res://Scenes/Explosion.tscn")

onready var shotgun_bot = load("res://Scenes/ShotgunnerBot.tscn")
onready var wheel_bot = load("res://Scenes/WheelBot.tscn")
onready var archer_bot = load("res://Scenes/ArcherBot.tscn")
onready var chain_bot = load("res://Scenes/ChainBot.tscn")
onready var flame_bot = load("res://Scenes/FlamethrowerBot.tscn")
onready var exterminator_bot = load("res://Scenes/ExterminatorBot.tscn")

onready var enemies = [shotgun_bot, wheel_bot, archer_bot, chain_bot, flame_bot, exterminator_bot]

var enemy_weights = [1, 1, 0.5, 1, 0.5, 0.3]


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
var marble
var audio

var out_of_control = false

onready var game_time = 0
var spawn_timer = 0
var enemy_soft_cap
var enemy_count = 5
var player_bullets = []
var enemy_hard_cap = 15

var evolution_level = 1

func _process(delta):
	game_time += delta
	spawn_timer -= delta
	timescale = lerp(timescale, target_timescale, delta*12)
	Engine.time_scale =  timescale
	
	if spawn_timer < 0:
		spawn_timer = 1
		enemy_soft_cap = 5 + game_time/15 #pow(1.3, game_time/60)
		
		if randf() < (1 - enemy_count/enemy_soft_cap):
			spawn_enemy()


func lerp_to_timescale(scale):
	target_timescale = scale
	audio.pitch_scale = scale
	
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
	
	enemy_count += 1
	var new_enemy = choose_weighted(enemies, enemy_weights).instance().duplicate()
	
	new_enemy.add_swap_shield(max(randf()*((game_time/30)/(3 + game_time/30)) - 0.2, 0))
	new_enemy.add_to_group("enemy")
	
	while(1 == 1): #Non-algorithmic function LOL
		var point = Vector2(-500 + randf()*2500, -250 + randf()*1150)
		if is_point_in_bounds(point) and is_point_offscreen(point):
			new_enemy.global_position = point - Vector2(0, new_enemy.get_node("CollisionShape2D").position.y)
			get_node("/root/MainLevel/WorldObjects/Characters").add_child(new_enemy)
			break
			

func reset():
	total_score = 0
	timescale = 0
	game_time = 0
	spawn_timer = 0
	enemy_count = 5
	player = null

func kill():
	player.dead = true
	swappable = false
	player.die()

func increase_score(value):
	if swap_bar.swap_threshold == 0:
		value *= 1.5
	else:
		var swap_thresh_reduction = value/20/(1 + game_time/200)
		swap_bar.set_swap_threshold(swap_bar.swap_threshold - swap_thresh_reduction)
		
	total_score += value
	score_display.score = total_score
	
	evolution_level += value/(300.0*int(evolution_level)) 
	print(evolution_level)
	score_display.modulate = [Color.blue, Color.green, Color.yellow, Color.orange, Color.red][int(evolution_level)]
	
func is_point_in_bounds(global_point):
	var ground_point = ground.world_to_map(global_point)
	var marble_point = marble.world_to_map(global_point)
	var obstacles_point = obstacles.world_to_map(global_point)
	
	return ground_point in ground.get_used_cells() and not marble_point in marble.get_used_cells() and not obstacles_point in obstacles.get_used_cells()
	
func is_point_offscreen(point):
	var from_player = point - player.global_position
	return abs(from_player.x) > 340 and abs(from_player.y) > 210
	
static func choose_weighted(values, weights):
	var cumu_weights = [weights[0]]
	for i in range(1, weights.size()):
		cumu_weights.append(weights[i] + cumu_weights[i-1])
	
	var rand = randf()*cumu_weights[cumu_weights.size()-1]
	for i in range(cumu_weights.size()):
		if rand < cumu_weights[i]:
			return values[i]
