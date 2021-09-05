extends KinematicBody2D

var source
var velocity = Vector2(100, 0)
var mass = 3
var decel_timer = 0
var damage_mult = 1.0

var lifetime = 999999
var invincible = false
var deflectable = true
var spectral = false

signal on_bullet_despawn

func _physics_process(delta):
	var col = move_and_collide(velocity*delta)
	
	var speed = velocity.length()
	decel_timer += delta
	if speed > 100 and decel_timer < 2:
		var decel = pow(min(decel_timer*(speed/200), 2), 1)
		velocity -= velocity*decel*delta
	#elif is_instance_valid(source):
		#velocity += 150*delta*(source.global_position - global_position).normalized()
		
	if col and not spectral:
		velocity = velocity.bounce(col.normal) * 0.9
		
	lifetime -= delta
	if lifetime < 0:
		detonate()


func _on_Area2D_area_entered(area):
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if entity.is_in_group('death orb'):
			if entity.source != source:
				decel_timer = 0
				var new_vel = (global_position - entity.global_position).normalized() * velocity.length() * 1.05
				entity.velocity += velocity - new_vel
				velocity = new_vel
			
		elif not entity.invincible and entity != source:
			decel_timer = 0
			var damage = pow(velocity.length(), 1.2)/30*damage_mult
			entity.take_damage(damage, source)
			var new_vel = (global_position - entity.global_position).normalized() * velocity.length()
			var delta_vel = new_vel - velocity
			velocity = new_vel * 1.05
			entity.velocity -= delta_vel*2/entity.mass
			
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (-delta_vel).angle(), sqrt(delta_vel.length())*30, damage, 30)
			
			
func take_damage(damage, source_, stun = 0):
	if source != source_:
		decel_timer = 0
	
func detonate():
	GameManager.spawn_explosion(global_position + Vector2(0, 10), source, 1.2, 30, 500)
	despawn()
	
func despawn():
	emit_signal('on_bullet_despawn', self)
	queue_free()
	

