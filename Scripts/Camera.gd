extends Camera2D

var anchor = null
var smooth_anchor_pos = Vector2.ZERO
var base_offset = Vector2.ZERO
var smooth_base_offset = base_offset

var mouse_follow = 0

var zoom_ = 1.0
var target_zoom = 1.0
var zoom_speed = 0.15
var linearity_hack = 1.0

var trauma = 0
var trauma_offset = Vector2.ZERO
export var decay = 5  # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).
	
func set_anchor(a):
	anchor = a
	smooth_anchor_pos = anchor.global_position

func _physics_process(delta):
	if anchor:
		base_offset = (get_global_mouse_position() - anchor.global_position)*mouse_follow
		smooth_anchor_pos = lerp(smooth_anchor_pos, anchor.global_position, 0.15)
		smooth_base_offset = lerp(smooth_base_offset, base_offset, 0.5)
		global_position = smooth_anchor_pos + trauma_offset
		
		if abs(zoom_ - target_zoom) > 0.001:
			var imtermeidate_lerp_target = min(zoom_ + linearity_hack, target_zoom) if target_zoom > zoom_ else max(zoom_ + linearity_hack, target_zoom)
			zoom_ = lerp(zoom_, imtermeidate_lerp_target, zoom_speed)
			zoom = Vector2(zoom_, zoom_)
		
		if trauma:
			trauma = max(trauma - trauma*decay*delta, 0)
			shake()
		else:
			trauma_offset = Vector2.ZERO
			
func lerp_zoom(z, speed = 0.15, lh = 1.0):
	target_zoom = z
	zoom_speed = speed
	linearity_hack = (target_zoom - zoom_)*lh
			
func set_trauma(amount, new_decay = 8):
	decay = min(decay, new_decay)
	trauma = max(trauma, amount)
			
func shake():
	var amount = pow(trauma, 2)
	rotation = max_roll * amount * (randf()-0.5)
	trauma_offset.x = max_offset.x * amount * (randf()-0.5)
	trauma_offset.y = max_offset.y * amount * (randf()-0.5)


