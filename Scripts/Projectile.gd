class_name Projectile
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
