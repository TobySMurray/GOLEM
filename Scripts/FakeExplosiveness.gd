extends Particles2D

var timer = 0
var prev_emitting = false

func _process(delta):
	if emitting:
		timer -= delta
		if timer < 0:
			emitting = false
				
	elif not prev_emitting:
		timer = 0.1
		
	prev_emitting = emitting
		
				
