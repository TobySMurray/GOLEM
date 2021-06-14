extends KinematicBody2D

var source
var velocity = Vector2(100, 0)
var mass = 3
var decel_timer = 0

var lifetime = 0
var invincible = false

func _physics_process(delta):
	var col = move_and_collide(velocity*delta)
	
	var speed = velocity.length()
	if speed > 100 and decel_timer < 2:
		var decel = pow(min(decel_timer*(speed/200), 2), 1)
		velocity -= velocity*decel*delta
		decel_timer += delta
	elif is_instance_valid(source):
		velocity += 150*delta*(source.global_position - global_position).normalized()
		
	if col:
		velocity = velocity.bounce(col.normal) * 0.9


func _on_Area2D_area_entered(area):
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible and entity != source:
			decel_timer = 0
			var damage = pow(velocity.length(), 1.3)/40
			entity.take_damage(damage, source)
			var new_vel = (global_position - entity.global_position).normalized() * velocity.length()
			var delta_vel = new_vel - velocity
			velocity = new_vel * 1.05
			entity.velocity -= delta_vel*2
			
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (-delta_vel).angle(), sqrt(delta_vel.length()*2)*30, damage, 30)
			
			
func take_damage(damage, source):
	decel_timer = 0
	pass
	
			
