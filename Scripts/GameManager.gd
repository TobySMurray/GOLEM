extends Node

var timescale = 1
var target_timescale = 1

var swappable = false


func _process(delta):
	timescale = lerp(timescale, target_timescale, delta*12)
	Engine.time_scale =  timescale

func lerp_to_timescale(scale):
	target_timescale = scale
	
	
func out_of_control():
	pass
	
