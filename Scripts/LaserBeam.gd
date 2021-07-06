class_name LaserBeam
extends Area2D

onready var sprite = $Sprite
var anim_frame = 0
var last_frame = 11
var anim_timer = 0.05
var style = 'red'

func _process(delta):
	anim_timer -= delta
	if anim_timer < 0:
		if anim_frame >= last_frame:
			queue_free()
			return
			
		if style == 'archer' and anim_frame == 4:
			anim_frame = 6
			
		anim_timer += 0.05
		anim_frame += 1
		sprite.material.set_shader_param('region', Rect2(anim_frame*32, 0, 32, 16))
		
		
# Called when the node enters the scene tree for the first time.
static func shoot_laser(origin, dir, width, source, damage, kb = 0, stun = 0, piercing = true, explosion_power = 0, style = 'red'):
	var laser = load('res://Scenes/LaserBeam.tscn').instance().duplicate()
	dir = dir.normalized()
	laser.global_position = origin
	laser.rotation = dir.angle()
	laser.style = style
	
	var space_state = source.get_world_2d().direct_space_state
	var result = space_state.intersect_ray(origin, origin + dir*10000, [source.get_node('Hitbox')], 1 if piercing else 5, true, !piercing)
	var dist = (result.position - origin).length() if result else 10000
	
	laser.scale = Vector2(dist/384.0, width/6.0)
	
	var tile_texture = style in ['red']
	laser.get_node('Sprite').material.set_shader_param('h_tiles', dist/32.0 if tile_texture else 1)
	source.get_node("/root").add_child(laser)
	
	if explosion_power > 0:
		GameManager.spawn_explosion(origin + dir*dist, source, explosion_power/50.0, explosion_power*0, 0)
	
	var collider = laser.get_node('CollisionShape2D')
	var query = Physics2DShapeQueryParameters.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_layer = 4
	query.exclude = []
	query.transform = collider.global_transform
	query.set_shape(collider.shape)
	
	var results = space_state.intersect_shape(query, 512)
	for col in results:
		if col['collider'].is_in_group("hitbox"):
			var enemy = col['collider'].get_parent()
			if not enemy.invincible and not enemy == source:
				enemy.take_damage(damage, source, stun)
				enemy.velocity += dir * kb
				
				if not enemy.is_in_group("bloodless"):
					GameManager.spawn_blood(enemy.global_position, dir.angle(), pow(kb, 0.5)*30, damage*0.75)

