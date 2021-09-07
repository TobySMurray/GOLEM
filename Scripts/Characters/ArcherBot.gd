extends "res://Scripts/Enemy.gd"

onready var attack_fx = $AttackFX
onready var attack_beam = $BeamRotator/AttackBeam
onready var sight_beam = $SightBeam
onready var raycast = $RayCast2D
onready var deflector_shape = $Deflector/CollisionShape2D


var walk_speed
var charge_time

var walk_speed_levels = [100, 110, 120, 130, 140, 150, 160]
var charge_time_levels = [1.5, 1.2, 1.0, 0.9, 0.8, 0.7, 0.6]

var speed_while_charging = 0
var beam_damage = 150
var beam_width = 1.0
var explosion_size = 0.5
var full_auto = false
var shanky = false
var triple_nock = false
var tazer_bomb = false

var charging = false
var charge_timer = 0
var raycast_endpoint = Vector2.ZERO

var bow_pos = Vector2.ZERO
var effective_aim_direction = Vector2.ONE

var stealth_mode = false
var stealth_timer = 0

onready var ai_target_point = global_position
var ai_move_timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.ARCHER
	max_health = 70
	flip_offset = -23
	init_healthbar()
	score = 50
	toggle_enhancement(false)
	
func toggle_playerhood(state):
	.toggle_playerhood(state)
	if state == false:
		charge_timer = 0
	
func toggle_enhancement(state):
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	charge_time = charge_time_levels[level]
	
	max_attack_cooldown = 1.5
	max_special_cooldown = 8 if state else 16
	speed_while_charging = 0
	beam_damage = 150
	beam_width = 1.0
	explosion_size = 0.5
	full_auto = false
	shanky = false
	triple_nock = false
	tazer_bomb = false
	
	if state == true:
		speed_while_charging = 50*GameManager.player_upgrades['vibro-shimmy']
		
		for i in range(GameManager.player_upgrades['slobberknocker_protocol']):
			explosion_size += 0.2
			beam_width += 2
			beam_damage *= 1.5
		
		if GameManager.player_upgrades['half-draw'] > 0:
			full_auto = true
			explosion_size -= 0.5
			charge_time *= 0.5 +  0.1*GameManager.player_upgrades['slobberknocker_protocol'] 
			beam_damage = 50
			beam_width *= 0.7
			
		for i in range(GameManager.player_upgrades['half-draw']-1):
			charge_time *= 0.5
			beam_damage *= 0.7
			
		shanky = GameManager.player_upgrades['scruple_inhibitor'] > 0
		
		for i in range (GameManager.player_upgrades['bomb_loader']):
			max_special_cooldown *= 0.5
		
		triple_nock = GameManager.player_upgrades['triple_nock'] > 0
		tazer_bomb = GameManager.player_upgrades['tazer_bomb'] > 0
		max_attack_cooldown = 0.1
	else:
		attack_cooldown = 0.75 + randf()*0.75
		
	.toggle_enhancement(state)
		


func misc_update(delta):
	ai_move_timer -= delta
	bow_pos = global_position + Vector2(-9 if facing_left else 9, 0)
	
	if charging:
		charge_timer -= delta
		if charge_timer < 0:
			release_attack()
	
	if stealth_mode:
		#sprite.material.set_shader_param('intensity', 1.0)
		stealth_timer -= delta
		if stealth_timer < 0:
			toggle_stealth(false)
		
	
func player_action():
	if not lock_aim:
		effective_aim_direction = (get_global_mouse_position() - bow_pos).normalized()
		
	if not attacking and (Input.is_action_just_pressed("attack1") or (full_auto and Input.is_action_pressed("attack1"))) and attack_cooldown < 0:
		charge_attack()
	elif Input.is_action_just_pressed("attack2") and special_cooldown < 0:
		special()
		
	if full_auto and Input.is_action_just_released('attack1') and charging:
		charging = false
		_on_AnimationPlayer_animation_finished('Attack')
		
	update_raycast()
	update_sight()
	
	if is_player:
		GameManager.camera.offset = lerp(GameManager.camera.offset, (get_global_mouse_position() - global_position)/2, 0.1)
	
func ai_action():
	var to_target_point = ai_target_point - global_position
	
	var to_player = GameManager.player.global_position - global_position
	var player_dist = to_player.length()
	
	if not lock_aim:
		aim_direction = (GameManager.player.global_position - global_position)
		effective_aim_direction = (GameManager.player.global_position - bow_pos).normalized()
		update_raycast()
		update_sight()
		
	if not attacking:
		sight_beam.visible = player_dist < 700
	
	if(to_target_point.length() > 5) and ai_move_timer > 0:
		target_velocity = to_target_point
		
	else:
		ai_target_point = global_position
		
		if not attacking and attack_cooldown < 0 and (raycast_endpoint - global_position).length() > player_dist - 10:
			ai_move_timer = 4
			if player_dist < 700:
				ai_target_point = global_position - aim_direction.rotated((randf()-0.5)*PI)*(20 + 50*randf())
				charge_attack()
	
	
func charge_attack():
	if stealth_mode:
		stealth_timer = min(stealth_timer, charge_time - 0.1)
		#toggle_stealth(false)
		
	attacking = true
	charging = true
	lock_aim = not full_auto
	override_speed = speed_while_charging
	
	charge_timer = charge_time
	play_animation("Ready")
	sight_beam.play("Flash")
	sight_beam.modulate = Color(1, 0, 0, 0.5)
	
func release_attack():
	charging = false
	attack_cooldown = max_attack_cooldown
	play_animation("Attack")
	
	sight_beam.stop()
	sight_beam.frame = 1
	
	attack_fx.flip_h = aim_direction.x < 0
	attack_fx.offset.x = -10 if attack_fx.flip_h else 7
	attack_fx.frame = 0
	attack_fx.play("Flash")
	
	var beam_length = (raycast_endpoint - global_position).length()
	var beam_dir = (raycast_endpoint - global_position)/beam_length
	
	if is_player:
		GameManager.camera.set_trauma(max(0.4, 0.7*beam_damage/150), 4 if beam_damage > 100 else 5)
	
	#melee_attack(attack_beam.get_node("CollisionShape2D"), beam_damage, 500, 0)
	
	if is_player and triple_nock:
		for i in range(-15, 16, 15):
			print(i)
			beam_length = (LaserBeam.shoot_laser(bow_pos, effective_aim_direction.rotated(deg2rad(i)), beam_width*6, self, beam_damage, 500, 0, true, 'archer', 0.5, 5, 500) - global_position).length()
			var dist = 50
			var delay = 0.05
			while dist < beam_length:
				var point = global_position + beam_dir.rotated(deg2rad(i))*dist
				GameManager.spawn_explosion(point, self, explosion_size, 40*explosion_size, 600*explosion_size, delay)
				dist += 50
				delay += 0.05
	else:
		beam_length = (LaserBeam.shoot_laser(bow_pos, effective_aim_direction, beam_width*6, self, beam_damage, 500, 0, true, 'archer', 0.5, 5, 500) - global_position).length()
		var dist = 50
		var delay = 0.05
		while dist < beam_length:
			var point = global_position + beam_dir*dist
			GameManager.spawn_explosion(point, self, explosion_size, 40*explosion_size, 600*explosion_size, delay)
			dist += 50
			delay += 0.05
		
func special():
	special_cooldown = max_special_cooldown
	attacking = true
	override_speed = 0
	charging = false
	sight_beam.stop()
	sight_beam.frame = 1
	play_animation("Special")
	
func toggle_stealth(state):
	stealth_mode = state

	if state == true:
		if is_player:
			GameManager.player_hidden = true
		stealth_timer = 3
		override_speed = max_speed*2
		sprite.modulate = Color(0.12, 0.12, 0.12, 0.5)
	else:
		if is_player:
			GameManager.player_hidden = false
		if not charging:
			override_speed = null
		sight_beam.frame = 0
		sprite.modulate = Color.white
	
func area_attack():
	invincibility_timer = 0.7
	if is_player and tazer_bomb:
		deflector_shape.scale = Vector2(10,10)
		Violence.melee_attack(self, deflector_shape, 20, 300, 3)
		deflector_shape.scale = Vector2(5,5)
	else:
		Violence.melee_attack(self, deflector_shape, 20, 300, 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func update_raycast():
	raycast.global_position = bow_pos
	raycast.cast_to = effective_aim_direction*2000
	raycast_endpoint = raycast.get_collision_point() if raycast.is_colliding() else (bow_pos + effective_aim_direction.normalized()*2000)

func update_sight():
	var beam_length = (raycast_endpoint - bow_pos).length()
	
	sight_beam.global_position = bow_pos
	sight_beam.rotation = effective_aim_direction.angle()
	sight_beam.scale.x = beam_length/80
	
func _on_Hitbox_area_entered(area):
	if not (stealth_mode and shanky):
		return
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible:
			entity.take_damage(50 + 10*GameManager.evolution_level, self)
			entity.velocity +=  300*(entity.global_position - global_position).normalized()
			GameManager.camera.set_trauma(0.45)
			if entity.is_in_group('enemy'):
				entity.invincibility_timer = min(stealth_timer, 0.7)
			
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (entity.global_position - global_position).angle(), 300, 50, 30)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Ready":
		play_animation("Charge")
		
	elif anim_name == "Attack" or anim_name == "Special":
		attacking = false
		lock_aim = false
		
		sight_beam.stop()
		sight_beam.modulate = Color(1, 1, 1, 0.5)
		if anim_name == 'Attack':
			sight_beam.frame = 0
			override_speed = null
		else:
			sight_beam.frame = 1

	elif anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()
			
func take_damage(damage, source, stun = 0):
	if not is_player and stun == 0 and damage < health and special_cooldown < 0 and not immobile and is_instance_valid(GameManager.player) and (GameManager.player.global_position - global_position).length() < 100:
		special()
		ai_move_timer = 4
		var space_state = get_world_2d().direct_space_state
		
		if space_state:
			var max_dist = 0
			for i in range(10):
				var dir = Vector2.ONE.rotated(randf()*2*PI)
				var result = space_state.intersect_ray(global_position, global_position + dir*10000, [get_node('Hitbox')], 1, true, false)
				var dist = (result['position'] - global_position).length() if result else 10000
				if dist > max_dist:
					max_dist = dist
					ai_target_point = global_position + dir*dist
		else:
			ai_target_point = 1000*Vector2.ONE.rotated(randf()*2*PI)
				
	.take_damage(damage, source, stun)
		
func die(killer = null):
	if stealth_mode:
		toggle_stealth(false)
	.die()

