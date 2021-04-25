extends Node

var timescale = 1
var target_timescale = 1

var swappable = false
var out_of_control = false

var swap_bar
var player
var camera
var transcender

func _process(delta):
	timescale = lerp(timescale, target_timescale, delta*12)
	Engine.time_scale =  timescale

func lerp_to_timescale(scale):
	target_timescale = scale
	
func toggle_out_of_control(state):
	out_of_control = state
	
