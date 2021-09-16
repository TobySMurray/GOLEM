class_name Bullet
extends Area2D

var source
var velocity = Vector2.ZERO
var lifetime = 10
var damage = 0
var mass = 0.25
var stun = 0
var piercing = false
var deflectable = true
var spectral = false
var ignored = []

var explosion_size = 0
var explosion_damage = 0
var explosion_kb = 0

var rotate_to_direction = false
var last_velocity = Vector2.ZERO

signal on_bullet_despawn

func _physics_process(delta):
	position += velocity*delta
	
	if rotate_to_direction:
		if velocity != last_velocity and velocity != Vector2.ZERO:
			last_velocity = velocity
			rotation = velocity.angle()
	
	lifetime -= delta
	#if lifetime < 0.5:
	#	visible = int(GameManager.game_time*20)%2 == 0
	if lifetime < 0:
		despawn()
			
func _on_Area2D_body_entered(body):
	if not (body.is_in_group("player") or body.is_in_group("enemy")) and not spectral and not body in ignored:
		despawn()

func _on_Area2D_area_entered(area):
	if area.is_in_group("destructible"):
		var entity = area.get_parent()
		entity.destroy()
		despawn()
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible and entity != source and not entity in ignored and not (entity.is_in_group('death orb') and entity.source == source):
			entity.take_damage(damage, source, stun)
			entity.velocity += velocity*mass/entity.mass
			
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (velocity).angle(), sqrt(velocity.length())*30, damage, 30)
			
			if not area.is_in_group("deflector") and not piercing and not (area.is_in_group('death orb') and entity.source == source):
				despawn()
				
func set_appearance(type):
	var sprite = get_node("AnimatedSprite")
	match(type):
		"flame":
			sprite.animation = "Flame"
			sprite.offset = Vector2(-2, 0)
			rotate_to_direction = true
			piercing = true
			
		"wave":
			sprite.animation = "Wave"
			sprite.offset = Vector2(-2, 0)
			rotate_to_direction = true
			get_node("CollisionShape2D").scale.y = 2
			
		_:
			sprite.animation = "Pellet"
			sprite.offset = Vector2(0, 0)
			rotate_to_direction = true
		
			
func despawn():
	GameManager.player_bullets.erase(self)
	emit_signal('on_bullet_despawn', self)
	
	if explosion_size > 0:
		GameManager.call_deferred('spawn_explosion(global_position', source, explosion_size, explosion_damage, explosion_kb)
	
	queue_free()
