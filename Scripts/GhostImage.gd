extends Sprite

var max_lifetime = 1.0
var lifetime = 1.0

func set_lifetime(time):
	max_lifetime = time
	lifetime = time
	
func copy_sprite(sprite):
	global_position = sprite.global_position
	texture = sprite.texture
	hframes = sprite.hframes
	vframes = sprite.vframes
	flip_h = sprite.flip_h
	flip_v = sprite.flip_v
	offset = sprite.offset
	scale = sprite.global_scale
	modulate = sprite.modulate
	frame = sprite.frame
	
func _process(delta):
	lifetime -= delta
	modulate.a = 0.5*max(lifetime, 0)/max_lifetime
	if lifetime < 0:
		queue_free()
