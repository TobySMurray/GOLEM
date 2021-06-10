extends KinematicBody2D

var source

var velocity = Vector2.ZERO
var max_accel = 300
var accel = max_accel
var max_speed = 5000
var damage = 5
var kb_speed = 1000
var mass = 0.1

var target_pos = Vector2.ZERO

var being_recalled = false
var recalled = false
var recall_timer = 0
var recall_offset = Vector2.ZERO

var invincible = false
var lifetime = 0

func recall():
	being_recalled = true
	recalled = false
	recall_timer = 0.3

func _physics_process(delta):
	if not being_recalled:
		velocity = move_and_slide(velocity)
		
		modulate = Color.white.linear_interpolate(Color(1, 0, 0.45), float(accel)/max_accel)
		if accel < max_accel:
			accel += 1
			
		var to_target = target_pos - global_position
		var target_dist = to_target.length()
		
		velocity += accel*(to_target/target_dist)*clamp(target_dist-5, 0, 20)*delta
		if target_dist < 10:
			velocity *= 0.9
		
		var speed = max(velocity.length(), 1)
		velocity -= velocity/speed*min(speed*speed*0.0005, speed)
	
	else:
		recall_timer -= delta
		global_position = lerp(global_position, target_pos, 0.2)
		recalled = (target_pos - global_position).length() < 7 or recall_timer < 0

func _on_Area2D_area_entered(area):
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible and entity != source:
			entity.take_damage(damage, source)
			var kb_vel= (entity.global_position - global_position).normalized() * kb_speed
			entity.velocity += kb_vel
			velocity -= kb_vel
			accel -= 5/mass
	
	elif area.is_in_group("bullet"):
		area.velocity = area.velocity.length()*(area.global_position - global_position).normalized()
		area.source = source
		area.lifetime = 2
			
func take_damage(damage, source):
	accel -= damage/(mass*3)
	pass
