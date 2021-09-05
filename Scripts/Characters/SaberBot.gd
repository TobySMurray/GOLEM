extends "res://Scripts/Enemy.gd"

onready var SaberRing = load("res://Scenes/SaberRing.tscn")
onready var GhostImage = load("res://Scenes/GhostImage.tscn")
onready var slash_trigger = $SlashTrigger
onready var slash_collider = $SlashCollider
onready var LOS_raycast = $LineOfSightRaycast


var walk_speed_levels = [90, 100, 110, 120, 130, 140, 150]
var dash_speed_levels = [250, 300, 333, 366, 400, 450, 500]
var slash_charges_levels = [1, 1, 2, 3, 4, 5, 5]
var max_special_cooldown_levels = [10, 6, 6, 6, 6, 6, 5]
var saber_ring_durability_levels = [0.1, 0.15, 0.175, 0.2, 0.225, 0.250, 0.275]

var walk_speed
var dash_speed
var slash_charges
var saber_ring_durability

var fractured_mind = false
var true_focus = false
var slash_damage = 150
var dash_time_dilation = 0.75
var saber_ring_deflect_level = 1
var saber_ring_accel = 300
var saber_ring_enemy_kb = 1000
var saber_range = 100

var saber_rings = [null, null, null]
var saber_ring_offsets = [Vector2(0.866, -0.5)*18, Vector2(0, 1)*18, Vector2(-0.866, -0.5)*18]
var sabers_sheathed = true
var waiting_for_saber_recall = false
var saber_rotation_timer = 0

var in_kill_mode = false
var kill_mode_buffered = false
var kill_mode_timer = 0
var remaining_slashes = 0

var base_color = Color.white

var ai_move_timer = 0
var ai_target_point = Vector2.ZERO

var ghost_timer = 0
var rage_color = Color(1, 0, 0.45)

func _ready():
	enemy_type = EnemyType.SABER
	max_health = 75
	flip_offset = -16
	healthbar.max_value = health
	max_attack_cooldown = 2
	score = 80
	init_healthbar()
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	dash_speed = dash_speed_levels[level]
	max_speed = walk_speed
	slash_charges = slash_charges_levels[level]
	max_special_cooldown = max_special_cooldown_levels[level]
	saber_ring_durability = saber_ring_durability_levels[level]
	
	fractured_mind = false
	true_focus = false
	slash_damage = 150
	dash_time_dilation = 0.75
	saber_ring_deflect_level = 1
	saber_ring_accel = 300
	saber_ring_enemy_kb = 1000
	saber_range = 100
	
	if state == true:
		if GameManager.player_upgrades['fractured_mind'] > 0:
			fractured_mind = true
			saber_range = 150
			saber_ring_accel = 400
			
		if GameManager.player_upgrades['true_focus'] > 0:
			true_focus = true
			slash_damage = 444
			dash_speed *= 1.5
			dash_time_dilation = 0.5
			
		max_special_cooldown -= GameManager.player_upgrades['overclocked_cooling']
		
		saber_ring_deflect_level += GameManager.player_upgrades['ricochet_simulation']
		
		saber_ring_durability *= 1 + 0.6*GameManager.player_upgrades['supple_telekinesis']
		for i in range(GameManager.player_upgrades['supple_telekinesis']):
			saber_ring_enemy_kb *= 0.66
			saber_ring_accel *= 0.8
		
	LOS_raycast.enabled = !state
	if state == true and in_kill_mode:
		end_kill_mode()
		special_cooldown = 0
	if state == false:
		remaining_slashes = min(remaining_slashes, 1)
		special_cooldown = 4
		attack_cooldown = 0
	if not sabers_sheathed and not waiting_for_saber_recall:
		recall_sabers()
		
	.toggle_enhancement(state)
	
func misc_update(delta):
	.misc_update(delta)
	ai_move_timer -= delta
			
	if not sabers_sheathed and not waiting_for_saber_recall:
		if fractured_mind:
			var accel_avg = 0
			for ring in saber_rings:
				accel_avg += ring.accel
				
			accel_avg /= 3
			for ring in saber_rings:
				ring.accel = accel_avg
				
			if accel_avg <= 0.2:
				recall_sabers()
			
			saber_rotation_timer -= delta
			if saber_rotation_timer < 0:
				saber_rotation_timer = 200.0/accel_avg
				var temp = saber_ring_offsets[2]
				saber_ring_offsets[2] = saber_ring_offsets[1]
				saber_ring_offsets[1] = saber_ring_offsets[0]
				saber_ring_offsets[0] = temp
				
		else:
			if saber_rings[0].accel <= 0:
				attack_cooldown = 2
				recall_sabers()
	
	if waiting_for_saber_recall:
		var sabers_recalled = true
		for ring in saber_rings:
			if is_instance_valid(ring) and not ring.recalled:
				sabers_recalled = false
				
		if sabers_recalled:
			waiting_for_saber_recall = false
			start_sheath()
			
	if in_kill_mode or special_cooldown < 0:
		sprite.light_mask = 2
	else:
		sprite.light_mask = 5
		
	if in_kill_mode:
		special_cooldown = max_special_cooldown
		kill_mode_timer -= delta
		if kill_mode_timer < 0:
			end_kill_mode()
			
		ghost_timer -= delta
		if ghost_timer < 0:
			ghost_timer = 30.0/dash_speed
			spawn_ghost_image()
			
			
	elif special_cooldown < 0:
		base_color = Color.white.linear_interpolate(rage_color, sin(GameManager.game_time*5)/2 + 0.5) 
	
func player_action():
	.player_action()
	if not attacking and not in_kill_mode and attack_cooldown < 0 and Input.is_action_just_pressed("attack1"):
		if sabers_sheathed:
			start_unsheath()
		else:
			recall_sabers()
			
	if not attacking and special_cooldown < 0 and Input.is_action_just_pressed("attack2"):
		if sabers_sheathed:
			start_kill_mode()
		else:
			kill_mode_buffered = true
			recall_sabers()
			
	if not sabers_sheathed:
		if waiting_for_saber_recall:
			for ring in saber_rings:
				if is_instance_valid(ring):
					ring.target_pos = global_position + Vector2(-29 if facing_left else 29, -8)
		else:
			var to_mouse = get_global_mouse_position() - global_position
			var limited_mouse_pos
			if to_mouse.length() < saber_range:
				limited_mouse_pos = global_position + to_mouse
			else:
				limited_mouse_pos = global_position + to_mouse.normalized()*saber_range
				
			if fractured_mind:
				for i in range(3):
					saber_rings[i].target_pos = limited_mouse_pos + saber_ring_offsets[i]
			else:
				saber_rings[0].target_pos = limited_mouse_pos

				
func ai_move():
	var to_player = GameManager.player.global_position - global_position
	var player_dist = to_player.length()
	var player_in_range = abs(to_player.x) < 200 and abs(to_player.y) < 140
	var player_in_sight = not LOS_raycast.is_colliding()
	aim_direction = to_player
	LOS_raycast.cast_to = to_player
	
	#action
	if not in_kill_mode:
		if special_cooldown < 0:
			if player_in_range and player_in_sight:
				if not sabers_sheathed and not waiting_for_saber_recall:
					kill_mode_buffered = true
					recall_sabers()
				elif not attacking and sabers_sheathed:
					start_kill_mode()
				
		if sabers_sheathed:
			if attack_cooldown < 0 and not attacking and not kill_mode_buffered:
				start_unsheath()
				
		elif not waiting_for_saber_recall:
			if special_cooldown < 0 or not player_in_sight:	
				orbit_sabers()
			else:
				var angle_offset = sin(GameManager.game_time*3)*PI/9
				saber_rings[0].target_pos = global_position + to_player.normalized().rotated(angle_offset)*60

	#move
	if in_kill_mode:
		if GameManager.player.dead:
			target_velocity = Vector2.ZERO
		else:
			var side = -sign(to_player.x)
			var to_point = GameManager.player.global_position + Vector2(20*side, 0) - global_position
			target_velocity = to_point
	
	elif special_cooldown < 0:
		if player_in_sight and not attacking:
			target_velocity = to_player
		else:
			target_velocity = Vector2.ZERO
			
	else:
		if ai_move_timer < 0:
			ai_move_timer = -1 if sabers_sheathed else randf() + 1
			if player_dist < 400:
				ai_target_point = global_position - to_player.rotated((randf()-0.5)*PI)*(20 + 30*randf())
			else:
				ai_target_point = global_position
		target_velocity = ai_target_point - global_position
				
func orbit_sabers():
	var angle = GameManager.game_time*PI*2
	saber_rings[0].target_pos = global_position + Vector2(cos(angle), sin(angle))*15
	

func start_kill_mode():
	in_kill_mode = true
	special_cooldown = max_special_cooldown
	override_speed = dash_speed
	slash_trigger.get_node("CollisionShape2D").set_deferred("disabled", false)
	remaining_slashes = slash_charges
	sprite.modulate = rage_color
	base_color = rage_color
	kill_mode_timer = 1
	
	if is_player:
		GameManager.lerp_to_timescale(dash_time_dilation)
	
func end_kill_mode():
	in_kill_mode = false
	override_speed = null
	slash_trigger.get_node("CollisionShape2D").set_deferred("disabled", true)
	sprite.modulate = Color.white
	base_color = Color.white
	
	if is_player:
		GameManager.lerp_to_timescale(1)
		
	if health <= 0 and not dead:
		die()
	
func slash(damage):
	attacking = true
	kill_mode_timer = 1
	play_animation("Special")
	slash_collider.position.x = -10 if facing_left else 10
	Violence.melee_attack(self, slash_collider, damage, 1000, 5)
	invincibility_timer = 0.25
	
	if is_player:
		GameManager.camera.set_trauma(0.6)
		if true_focus:
			GameManager.set_timescale(0.02, 0.3)
		else:
			GameManager.timescale = 0.0
		
func end_slash():
	attacking = false
	remaining_slashes -= 1
	if remaining_slashes <= 0:
		end_kill_mode()
			
func start_unsheath():
	lock_aim = true
	attacking = true
	play_animation("Unsheath")
	
func recall_sabers():
	for ring in saber_rings:
		if is_instance_valid(ring):
			ring.recall()
				
	lock_aim = true
	attacking = true
	waiting_for_saber_recall = true
	
func start_sheath():
	for i in range(len(saber_rings)):
		if is_instance_valid(saber_rings[i]):
			saber_rings[i].queue_free()
		saber_rings[i] = null
		
	sabers_sheathed = true
	play_animation("Sheath")
	
func on_sabers_sheathed():
	lock_aim = false
	attacking = false
	walk_anim = "Walk"
	idle_anim = "Idle"
	if kill_mode_buffered:
		kill_mode_buffered = false
		start_kill_mode()
	
func on_sabers_unsheathed():
	sabers_sheathed = false
	for i in range(3 if fractured_mind else 1):
		var saber_ring = SaberRing.instance().duplicate()
		saber_ring.source = self
		saber_ring.global_position = global_position + Vector2(-29 if facing_left else 29, -8)
		saber_ring.visible = true
		saber_ring.mass = saber_ring_durability
		saber_ring.max_accel = saber_ring_accel
		saber_ring.deflect_level = saber_ring_deflect_level
		saber_ring.kb_speed = saber_ring_enemy_kb
		saber_rings[i] = saber_ring
		get_parent().add_child(saber_ring)
	lock_aim = false
	attacking = false
	walk_anim = "Walk Saberless"
	idle_anim = "Idle Saberless"

func _on_SlashTrigger_area_entered(area):
	if in_kill_mode and not attacking and not area.get_parent() == self and area.is_in_group("hitbox") and not area.get_parent().invincible:
		velocity = (area.global_position - global_position).normalized() * 1000
		if true_focus and area.get_parent().is_in_group('enemy') and area.get_parent().is_miniboss and area.get_parent().swap_shield_health > 0:
			slash(area.get_parent().swap_shield_health)
		else:
			slash(slash_damage)
		
func on_swap():
	if not is_player:
		special_cooldown = 2
		
func spawn_ghost_image():
	var new_ghost = GhostImage.instance().duplicate()
	get_parent().add_child(new_ghost)
	new_ghost.copy_sprite(sprite)
	new_ghost.set_lifetime(0.4)
	
func take_damage(damage, source, stun = 0):
	if in_kill_mode:
		damage /= 2
	.take_damage(damage, source, stun)
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()
		
func die(killer = null):
	if not (true_focus and in_kill_mode):
		.die()
		
func actually_die():
	for i in range(len(saber_rings)):
		if is_instance_valid(saber_rings[i]):
			saber_rings[i].queue_free()
			
	.actually_die()



