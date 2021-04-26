extends Node

onready var explosion = load("res://Scenes/Explosion.tscn")

onready var shotgun_bot = load("res://Scenes/ShotgunnerBot.tscn")
onready var wheel_bot = load("res://Scenes/WheelBot.tscn")
onready var archer_bot = load("res://Scenes/ArcherBot.tscn")
onready var chain_bot = load("res://Scenes/ChainBot.tscn")
onready var flame_bot = load("res://Scenes/FlamethrowerBot.tscn")
onready var exterminator_bot = load("res://Scenes/ExterminatorBot.tscn")

onready var enemies = [shotgun_bot, wheel_bot, archer_bot, chain_bot, flame_bot, exterminator_bot]
var weights = [1, 1, 0.75, 1, 1, 0.5]

var timescale = 1
var target_timescale = 1

var swappable = false
var out_of_control = false

var swap_bar
var player
var camera
var transcender
var total_score = 0
var score_display
var ground
var obstacles
var audio

onready var game_time = 0
var spawn_timer = 0
var enemy_count = 5

func _process(delta):
	game_time += delta
	spawn_timer -= delta
	timescale = lerp(timescale, target_timescale, delta*12)
	Engine.time_scale =  timescale
	
	if spawn_timer < 0:
		print(enemy_count)
		spawn_timer = 5/pow(2, game_time/60)
		
		if randf() < (1 - enemy_count/(5.0 + enemy_count)):
			spawn_enemy()

func lerp_to_timescale(scale):
	target_timescale = scale
	audio.pitch_scale = scale
	
func toggle_out_of_control(state):
	out_of_control = state
	
func spawn_explosion(pos, size = 1, damage = 20, force = 200, delay = 0):
	var new_explosion = explosion.instance().duplicate()
	new_explosion.global_position = pos
	new_explosion.scale = Vector2(size, size)
	new_explosion.damage = damage
	new_explosion.force = force
	new_explosion.delay_timer = delay
	get_node("/root").add_child(new_explosion)
	
func spawn_enemy():
	enemy_count += 1
	var new_enemy = choose_weighted(enemies, weights).instance().duplicate()
	
	new_enemy.add_swap_shield(max(randf()*((1*game_time/60)/(3 + game_time/60)) - 0.2, 0))
	new_enemy.add_to_group("enemy")
	
	while(1 == 1): #Non-algorithmic function LOL
		var point = Vector2(-500 + randf()*1500, -250 + randf()*650)
		if is_point_in_bounds(point):
			new_enemy.global_position = point
			get_node("/root/MainLevel/WorldObjects/Characters").add_child(new_enemy)
			break
			

func kill():
	player.die()

func increase_score(value):
	print("score")
	enemy_count -= 1
	total_score += value
	score_display.score = total_score
	
func is_point_in_bounds(global_point):
	var tile_point = ground.world_to_map(global_point)
	return tile_point in ground.get_used_cells()
	
static func choose_weighted(values, weights):
	var cumu_weights = [weights[0]]
	for i in range(1, weights.size()):
		cumu_weights.append(weights[i] + cumu_weights[i-1])
	
	var rand = randf()*cumu_weights[cumu_weights.size()-1]
	for i in range(cumu_weights.size()):
		if rand < cumu_weights[i]:
			return values[i]
