extends AnimatedSprite

onready var stopped = $Stopped
onready var boss = $Boss
onready var collider = $Area2D/CollisionShape2D

var selected_enemy
signal selected_enemy_signal
var moon_visible = false

func _physics_process(delta):
	selected_enemy = null
	if moon_visible:
		modulate = lerp(modulate, Color(1,1,1,1), 0.1)
		
		var space_rid = get_world_2d().space
		var space_state = Physics2DServer.space_get_direct_state(space_rid)

		var query = Physics2DShapeQueryParameters.new()
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.collision_layer = 4
		query.exclude = []
		query.transform = collider.global_transform
		query.set_shape(collider.shape)

		var results = space_state.intersect_shape(query, 512)
		var min_dist = 999999999
		
		for col in results:
			if col['collider'].is_in_group("hitbox"):
				var body = col['collider'].get_parent()
				if body.is_in_group("enemy") and body.swap_shield_health <= 0 and body.health > 0:
					var dist = (body.global_position - global_position).length_squared()
					if dist < min_dist:
						selected_enemy = body
						
		if selected_enemy:
			self.modulate.a = 1.0
			GameManager.transcender.enemy_is_selected = true
		else:
			self.modulate.a = 0.3
			GameManager.transcender.enemy_is_selected = false
			
	if !moon_visible:
		modulate = lerp(modulate, Color(1,1,1,0), 0.2)
		

func _on_Area2D_body_entered(body):
	return
	if moon_visible and body.is_in_group("enemy") and body.swap_shield_health <= 0 and body.health > 0:
		selected_enemy = body
		emit_selected_enemy_signal(true)
		
func _on_Area2D_body_exited(body):
	return
	if moon_visible and body.is_in_group("enemy") and body.swap_shield_health <= 0 and body.health > 0:
		selected_enemy = null
		emit_selected_enemy_signal(false)

func emit_selected_enemy_signal(state):
	if moon_visible:
		self.modulate.a = 1 if state else 0.3
		emit_signal("selected_enemy_signal", state)

func _on_Slow_finished():
	stopped.play()


func _on_Speed_finished():
	stopped.stop()
