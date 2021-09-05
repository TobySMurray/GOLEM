extends Area2D

var violence = load('res://Scripts/Violence.gd') #Can't use static typing until GDscript 4.0 due to cicular reference
var source
var velocity = Vector2.ZERO
var lifetime = 10
var damage = 30
var mass = 1
var num_frags = 6
var frag_damage = 10
var frag_speed = 150
var stun = 0
var frag_type = 'pellet'

var deflectable = true
var spectral = false

onready var last_position = global_position - velocity.normalized()*10
var last_velocity = Vector2.ZERO

func _physics_process(delta):
	last_position = global_position
	position += velocity*delta
	lifetime -= delta
	#if lifetime < 0.5:
	#	visible = int(GameManager.game_time*20)%2 == 0
	if lifetime < 0:
		despawn()

func _on_Area2D_body_entered(body):
	if not (body.is_in_group("player") or body.is_in_group("enemy")) and not spectral:
		explode(body)

func _on_Area2D_area_entered(area):
	if area.is_in_group("destructible"):
		var entity = area.get_parent()
		entity.destroy()
		explode(false)
		
	elif area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible and entity != source:
			entity.take_damage(damage, source)
			entity.velocity += velocity*mass/entity.mass
			
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (velocity).angle(), sqrt(velocity.length())*30, damage, 30)
			
			if not area.is_in_group("deflector") and not (area.is_in_group('death orb') and entity.source == source):
				explode()
				
func explode(wall = null):
#	var from_wall
#	if wall:
#		from_wall = (global_position - wall.global_position).normalized()
		
	for i in range(num_frags):
		var dir = Vector2.ONE.rotated(randf()*2*PI)
		var speed = (0.5 + randf()*0.5)*frag_speed
		var bullet = violence.shoot_bullet(source, last_position, dir*speed, frag_damage, 0.25, 2, frag_type, stun)
#		if wall:
#			bullet.ignored_bodies = [wall]
	despawn()
			
func despawn():
	queue_free()

