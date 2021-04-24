extends Node

var timescale = 1
var target_timescale = 1

func process(delta):
	timescale = lerp(timescale, target_timescale, delta*4)
	Engine.time_scale =  timescale

func lerp_to_timescale(scale):
	target_timescale = scale
	
	

	
