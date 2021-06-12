extends Particles2D

var timer = 2

func _process(delta):
	timer -= delta
	if timer < 0:
		queue_free()
