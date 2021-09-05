extends Area2D

var source
var velocity = Vector2.ZERO
var lifetime = 10
var damage = 0
var mass = 0.25
var stun = 0
var deflectable = true

var rotate_to_direction = false
var last_velocity = Vector2.ZERO

signal on_bullet_despawn

func _physics_process(delta):
	position += velocity*delta
	
	if velocity != last_velocity and velocity != Vector2.ZERO:
		last_velocity = velocity
		rotation = velocity.angle()
	
	lifetime -= delta
	#if lifetime < 0.5:
	#	visible = int(GameManager.game_time*20)%2 == 0
	if lifetime < 0:
		despawn()
			
	

func _on_Area2D_body_entered(body):
	if not (body.is_in_group("player") or body.is_in_group("enemy")):
		despawn()

func _on_Hitbox_area_entered(area):
	if area.is_in_group("destructible"):
		var entity = area.get_parent()
		entity.destroy()
		
	elif area.is_in_group('bullet'):
		area.velocity = area.velocity.length()*global_position.direction_to(area.global_position)
		
	elif area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible and entity != source and not (entity.is_in_group('death orb') and entity.source == source):
			entity.take_damage(damage, source, stun)
			var a = velocity.y/velocity.x
			var c = global_position.y - a*global_position.x
			var dist = abs(a*entity.global_position.x - entity.global_position.y + c)/sqrt(a*a + 1)
			var side = sign(sin(velocity.angle_to(entity.global_position - global_position)))
			
			var kb_vel = velocity*mass/entity.mass
			kb_vel += kb_vel.tangent()*side*(dist / (kb_vel.length()/15.0))
			
			entity.velocity += kb_vel
			
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (velocity).angle(), sqrt(velocity.length())*30, damage, 30)
			
		
			
func despawn():
	emit_signal('on_bullet_despawn', self)
	queue_free()

