extends Area2D

onready var anim = $AnimatedSprite

var source
var damage = 0
var force = 0
var delay_timer = 0
var exploded = false

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _process(delta):
	delay_timer -= delta
	if not exploded and delay_timer < 0:
		explode()
		
	if delay_timer < -2:
		queue_free()
		
func explode():
	exploded = true
	anim.frame = 0
	anim.play("Explode")
	
	var space_rid = get_world_2d().space
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	var collider = $CollisionShape2D
	
	var query = Physics2DShapeQueryParameters.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_layer =  6
	query.exclude = []
	query.transform = collider.global_transform
	query.set_shape(collider.shape)
	
	var results = space_state.intersect_shape(query, 512)
	for col in results:
		if col['collider'].is_in_group('death orb'):
			var orb = col['collider'].get_parent()
			if orb.source != source:
				orb.velocity += (orb.global_position - global_position).normalized() * force / orb.mass
			
		elif col['collider'].is_in_group('bullet'):
			var bullet = col['collider']
			if not bullet.source == source:
				bullet.lifetime += 2
				bullet.velocity = (bullet.global_position - global_position).normalized() * bullet.velocity.length()
				
		elif col['collider'].is_in_group("hitbox"):
			var enemy = col['collider'].get_parent()
			
			if enemy.is_in_group('enemy pillar'):
				damage *= 3
			
			if not enemy.invincible and not enemy == source:
				enemy.take_damage(damage, source)
				var kb_vel = (enemy.global_position - global_position).normalized() * force / enemy.mass
				enemy.velocity += kb_vel
				
				if not enemy.is_in_group("bloodless"):
					GameManager.spawn_blood(enemy.global_position, kb_vel.angle(), force, damage)
			
		

