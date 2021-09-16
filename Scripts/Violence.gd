class_name Violence
extends Node

const Bullet = preload("res://Scenes/Bullet.tscn")
const FlakBullet = preload("res://Scenes/FlakBullet.tscn")
const VortexWave = preload("res://Scenes/VortexWave.tscn")

static func shoot_bullet(source_, origin, vel, damage_ = 10, mass_ = 0.25, lifetime_ = 10, type = "pellet", stun_ = 0, size = Vector2.ONE, explosion_size = 0, explosion_damage = 0, explosion_kb = 0):
	var new_bullet = Bullet.instance().duplicate()
	new_bullet.global_position = origin
	new_bullet.source = source_
	new_bullet.velocity = vel * 0.8 #This coefficient is unbelievably eldritch but I'm too afraid to change it
	new_bullet.damage = damage_
	new_bullet.mass = mass_
	new_bullet.lifetime = lifetime_
	new_bullet.stun = stun_
	new_bullet.scale = size
	new_bullet.explosion_size = explosion_size
	new_bullet.explosion_damage = explosion_damage
	new_bullet.explosion_kb = explosion_kb
	new_bullet.set_appearance(type)
	GameManager.projectiles_node.call_deferred('add_child', new_bullet)
	
	if is_instance_valid(source_) and source_.is_in_group("player"):
		GameManager.player_bullets.append(new_bullet)
		
	return new_bullet
		
static func shoot_flak_bullet(source_, origin, vel, damage_ = 30, mass_ = 1, lifetime_ = 10, num_frags = 6, frag_damage = 10, frag_speed = 150, frag_type = 'pellet'):
	var new_bullet = FlakBullet.instance().duplicate()
	new_bullet.global_position = origin
	new_bullet.source = source_
	new_bullet.velocity = vel * 0.8
	new_bullet.damage = damage_
	new_bullet.mass = mass_
	new_bullet.lifetime = lifetime_
	new_bullet.num_frags = num_frags
	new_bullet.frag_damage = frag_damage
	new_bullet.frag_speed = frag_speed
	new_bullet.frag_type = frag_type
	GameManager.projectiles_node.add_child(new_bullet)
	return new_bullet
	
static func shoot_vortex_wave(source_, origin, vel, damage_, mass_, lifetime_, stun_ = 0, size = Vector2.ONE):
	var wave = VortexWave.instance().duplicate()
	wave.global_position = origin
	wave.source = source_
	wave.velocity = vel
	wave.damage = damage_
	wave.mass = mass_
	wave.lifetime = lifetime_
	wave.stun = stun_
	wave.scale = size
	GameManager.projectiles_node.add_child(wave)
	return wave
	
static func melee_attack(source, collider, damage = 10, force = 50, deflect_power = -1, stun = 0):
	var space_rid = source.get_world_2d().space
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	
	var query = Physics2DShapeQueryParameters.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_layer =  6 if deflect_power > -1 else 4
	query.exclude = []
	query.transform = collider.global_transform
	query.set_shape(collider.shape)
	
	var results = space_state.intersect_shape(query, 512)
	var hit_entities = []
	for col in results:
		if col['collider'].is_in_group("hitbox"):
			var enemy = col['collider'].get_parent()
			if not enemy.invincible and not enemy == source:
				hit_entities.append(enemy)
				enemy.take_damage(damage, source, stun)
				
				if typeof(force) == TYPE_VECTOR2:
					enemy.velocity += force / enemy.mass
				else:
					enemy.velocity += (enemy.global_position - source.global_position).normalized() * force / enemy.mass
				
				if not enemy.is_in_group("bloodless"):
					GameManager.spawn_blood(enemy.global_position, (enemy.global_position - source.global_position).angle(), pow(force, 0.5)*30, damage*0.75)
				
		elif col['collider'].is_in_group("bullet"):
			var bullet = col['collider']
			if bullet.deflectable:
				hit_entities.append(bullet)
				
				if deflect_power > 0:
					var target = bullet.source
					var deflect_case
					if is_instance_valid(target):
						if target == source:
							deflect_case = 0
						elif deflect_power == 1:
							deflect_case = 1
						else:
							deflect_case = 2
					else:
						deflect_case = 1
						
					if deflect_case == 0:
						pass
						#bullet.velocity *= 1 + 0.5*deflect_power 
					else:
						bullet.source = source
						bullet.lifetime += 1
						bullet.stun = max(bullet.stun, stun*0.5)
						if deflect_case > 1:
							bullet.lifetime += 2
							var bullet_speed = bullet.velocity.length()
							var dir = (target.global_position - bullet.global_position).normalized() if is_instance_valid(target) else -bullet.velocity/bullet_speed
							bullet.velocity =  dir*max(50, bullet_speed)*deflect_power
						else:
							bullet.velocity = -bullet.velocity*deflect_power			
	return hit_entities
