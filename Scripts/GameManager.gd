extends Node

onready var explosion = load("res://Scenes/Explosion.tscn")

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

func _process(delta):
	timescale = lerp(timescale, target_timescale, delta*12)
	Engine.time_scale =  timescale

func lerp_to_timescale(scale):
	target_timescale = scale
	
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
	
func increase_score(value):
	total_score += value
	score_display.score = total_score
