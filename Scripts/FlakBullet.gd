extends Area2D

onready var Bullet = load('res://Scenes/Bullet.tscn')

var source
var velocity = Vector2.ZERO
var lifetime = 10
var damage = 30
var mass = 1
var num_frags = 6
var frag_damage = 10
var frag_speed = 150
var frag_type = 'pellet'

var rotate_to_direction = false
var last_velocity = Vector2.ZERO

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
	if not (body.is_in_group("player") or body.is_in_group("enemy")):
		explode()

func _on_Area2D_area_entered(area):
	if area.is_in_group("destructible"):
		var entity = area.get_parent()
		entity.destroy()
		explode()
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible and entity != source:
			entity.take_damage(damage, source)
			entity.velocity += velocity*mass/entity.mass
			
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (velocity).angle(), sqrt(velocity.length())*30, damage, 30)
			
			if not area.is_in_group("deflector"):
				explode()
				
func explode():
	for i in range(num_frags):
		var dir = Vector2.ONE.rotated(randf()*2*PI)
		var speed = (0.5 + randf()*0.5)*frag_speed
		shoot_bullet(dir*speed)
	despawn()
			
func shoot_bullet(vel):
	var new_bullet = Bullet.instance().duplicate()
	new_bullet.global_position = global_position
	new_bullet.source = source
	new_bullet.velocity = vel
	new_bullet.damage = frag_damage
	new_bullet.mass = 0.25
	new_bullet.lifetime = 2
	new_bullet.set_appearance(frag_type)
	get_node("/root").add_child(new_bullet)
	
	if source.is_in_group("player"):
		GameManager.player_bullets.append(new_bullet)
			
func despawn():
	GameManager.player_bullets.erase(self)
	queue_free()
