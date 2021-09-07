extends Area2D

onready var slow_audio = $Slow 
onready var stopped_audio = $Stopped
onready var speed_audio = $Speed
onready var boss_audio = $Boss
onready var collider = $CollisionShape2D
onready var sprite = $AnimatedSprite
onready var grayscale_filter = $CanvasLayer2/GrayscaleFilter

var selected_enemy
signal selected_enemy_signal
var moon_visible = false
var visual_snap_pos = Vector2.ZERO
var grayscale_intensity = 0.0

func _physics_process(delta):
	selected_enemy = null
	grayscale_filter.rect_position = get_global_transform_with_canvas().origin - Vector2(750, 750)
	
	
	if moon_visible:
		modulate = lerp(modulate, Color(1,1,1,1), 0.1)
		grayscale_intensity = lerp(grayscale_intensity, 1.0, 0.1)
		
		var space_rid = get_world_2d().space
		var space_state = Physics2DServer.space_get_direct_state(space_rid)

		var query = Physics2DShapeQueryParameters.new()
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.collision_layer = 4
		query.exclude = []
		query.transform = collider.global_transform
		query.set_shape(collider.shape)

		var results = space_state.intersect_shape(query, 64)
		var min_dist = 999999999
		
		for col in results:
			var body = col['collider'].get_parent() if col['collider'].is_in_group("hitbox") else col['collider']

			if Host.is_valid_swap_target(body):
				var dist = (body.global_position - global_position).length_squared()
				if (body.is_in_group('boss') or (body.is_in_group('enemy') and body.is_miniboss and body.enemy_evolution_level > GameManager.evolution_level)):
					selected_enemy = body
					break
				elif dist < min_dist:
					min_dist = dist
					selected_enemy = body
						
		if selected_enemy:
			self.modulate.a = 1.0
			GameManager.world.transcender.enemy_is_selected = true
			if (sprite.global_position - selected_enemy.global_position).length() > 5:
				sprite.position = lerp(sprite.position, selected_enemy.global_position - global_position, 15*delta/GameManager.timescale)
			else:
				sprite.position = selected_enemy.global_position - global_position
		else:
			self.modulate.a = 0.3
			GameManager.world.transcender.enemy_is_selected = false
			if sprite.position.length() > 5:
				sprite.position = lerp(sprite.position, Vector2.ZERO, 15*delta/max(GameManager.timescale, 0.01))
			else:
				sprite.position = Vector2.ZERO
			
	else:
		modulate = lerp(modulate, Color(1,1,1,0), 0.2)
		grayscale_intensity = lerp(grayscale_intensity, 0.0, 0.2)
		
	grayscale_filter.material.set_shader_param('INTENSITY', grayscale_intensity)
		
func draw_transcender(origin):
	var transcender_curve = Curve2D.new()
	var endpoint = sprite.global_position
	
	var p0_vertex = origin # First point of first line segment
	var p0_out = (Vector2(origin.x, origin.y - 75) - origin) # Second point of first line segment
	var p1_in = (Vector2(endpoint.x, endpoint.y - 75) - endpoint) # First point of second line segment
	var p1_vertex = endpoint # Second point of second line segment
	
	var p0_in = Vector2.ZERO # This isn't used for the first curve
	var p1_out = Vector2.ZERO # Not used unless another curve is added

	transcender_curve.add_point(p0_vertex, p0_in, p0_out);
	transcender_curve.add_point(p1_vertex, p1_in, p1_out);
	
	GameManager.world.transcender.draw_transcender(transcender_curve)
		

func _on_Slow_finished():
	stopped_audio.play()
