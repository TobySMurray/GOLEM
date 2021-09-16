extends "res://Scripts/Enemy.gd"

onready var death_orb = load("res://Scenes/DeathOrb.tscn")

var orbs = [null, null, null, null, null, null, null, null]
onready var stands = [$JojoReference]
onready var tethers = [$Line2D]
onready var attack_collider = $AttackCollider/CollisionShape2D
onready var orb_detonate_audio = $OrbDetonateAudio

var walk_speed = 0
var smack_recharge = 0
var smack_speed = 0

var walk_speed_levels = [80, 120, 135, 150, 165, 180, 195]
var smack_recharge_levels = [1.1, 0.75, 0.65, 0.55, 0.5, 0.45, 0.4]
var smack_speed_levels = [300, 400, 450, 500, 533, 566, 600]

var orb_size = 1.0
var num_orbs = 1
var orb_damage_mult = 1.0
var tetherball_mode = false
var precision_mode = false

var orbs_are_accelerating = false

var move_timer = 0
var ai_target_pos = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.SORCERER
	max_health = 180
	score = 100
	mass = 2
	flip_offset = -13
	init_healthbar()
	for stand in stands:
		stand.hide()
	for tether in tethers:
		tether.visible = false
	toggle_enhancement(false)
	max_special_cooldown = 2
	
func toggle_playerhood(state):
	.toggle_playerhood(state)
	for stand in stands:	
		stand.collision_layer = 0 if is_player else 4
	
func toggle_enhancement(state):
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	smack_recharge = smack_recharge_levels[level]
	smack_speed = smack_speed_levels[level]
	max_attack_cooldown = smack_recharge
	
	orb_size = 1.0
	num_orbs = 1
	orb_damage_mult = 1.0
	tetherball_mode = false
	precision_mode = false
	
	if state == true:
		orb_size += GameManager.player_upgrades['elastic_containment']
		
		num_orbs += GameManager.player_upgrades['parallelized_drones']
		for i in range(min(GameManager.player_upgrades['parallelized_drones'], 2)):
			orb_size *= 0.75
			orb_damage_mult -= 0.2/(i + 1)
		
		if GameManager.player_upgrades['docked_drones'] > 0:
			tetherball_mode = true
			smack_speed *= 2
			orb_damage_mult *= 0.6
			
		precision_mode = GameManager.player_upgrades['precision_handling'] > 0	
			
	else:
		if is_any_orb_valid():
			special_cooldown = 2
			attacking = true
			play_animation("Special")
		
	if len(orbs) > num_orbs:
		for i in range(len(orbs) - num_orbs):
			if is_instance_valid(orbs[i + num_orbs]):
				orbs[i + num_orbs].detonate()
	
	if num_orbs > len(stands):
		for i in range(num_orbs - len(stands)):
			var stand = stands[0].duplicate()
			stands.append(stand)
			add_child(stand)
			var tether = tethers[0].duplicate()
			tethers.append(tether)
			add_child(tether)
	elif num_orbs < len(stands):
		for i in range(len(stands) - num_orbs):
			stands[-1].queue_free()
			stands.pop_back()
			tethers[-1].queue_free()
			tethers.pop_back()
			
	for stand in stands:
		stand.collision_layer = 0 if is_player else 4
		if precision_mode:
			stand.sprite.play("Walk")
			
	.toggle_enhancement(state)
	
	
func misc_update(delta):
	move_timer -= delta
	
	for i in range(num_orbs):
		if is_instance_valid(orbs[i]):
			tethers[i].visible = true
			tethers[i].set_point_position(1, (orbs[i].global_position - global_position)/scale.x)
			orbs[i].lifetime = 2
			
			if tetherball_mode:
				var dist = (orbs[i].global_position - global_position).length()
				if dist > 50:
					orbs[i].velocity -= (orbs[i].global_position - global_position)*20*delta
					orbs[i].velocity *= 0.95
				else:
					orbs[i].velocity *= 0.98
					if num_orbs > 1 and orbs[i].decel_timer > 0.5:
						for j in range(num_orbs):
							if j != i and is_instance_valid(orbs[j]):
								var disp = (orbs[i].global_position - orbs[j].global_position)
								var sqr_dist = max(25, disp.length_squared()/(orb_size*orb_size))
								if sqr_dist < 900:
									orbs[i].velocity += disp/sqr_dist*delta*1000
				
		else:
			tethers[i].visible = false

		if precision_mode:
			if orbs_are_accelerating:
				accelerate_orbs(get_global_mouse_position(), delta)
			else:
				decelerate_orbs()
			
		else:
			if stands[i].visible:
				if stands[i].timer < 1.1 and stands[i].next_smack_vel.x != 0:
					if is_instance_valid(orbs[i]):
						orbs[i].velocity = stands[i].next_smack_vel
						orbs[i].decel_timer = 0
						stands[i].get_node('AudioStreamPlayer2D').play()
						if is_player:
							GameManager.camera.set_trauma(0.5)
							
					stands[i].next_smack_vel = Vector2.ZERO

func player_action():
	if is_any_orb_valid():
		if precision_mode:
			orbs_are_accelerating = Input.is_action_pressed("attack1")

		else:
			if Input.is_action_just_pressed('attack1') and attack_cooldown < 0:
				attack_cooldown = smack_recharge
				smack_orbs(get_global_mouse_position())
					
	elif Input.is_action_just_pressed('attack1') and attack_cooldown < 0:
		attacking = true
		play_animation("Attack")
			
	if Input.is_action_just_pressed('attack2') and special_cooldown < 0:
		special_cooldown = 2
		attacking = true
		play_animation("Special")
		

func ai_move():
	var to_player = GameManager.player.global_position - global_position
	var player_dist = to_player.length()
	var player_dir = to_player/player_dist
	
	if move_timer < 0:
		move_timer = 2
		ai_target_pos = global_position
		
		if is_instance_valid(orbs[0]):
			if player_dist < 300:
				ai_target_pos = global_position - 1000*player_dir.rotated((randf()-0.5)*60)
				
		elif player_dist > 200 and player_dist < 500:
			ai_target_pos = GameManager.player.global_position
			
	elif move_timer < 1:
		target_velocity = (ai_target_pos - global_position).normalized()*walk_speed
	else:
		target_velocity = Vector2.ZERO
			

func ai_action():
	aim_direction = (GameManager.player.global_position - global_position)
	var orb = orbs[0]
	
	if attack_cooldown < 0 and not attacking:
		if is_instance_valid(orb):
			var orb_dist =  (GameManager.player.global_position - orb.global_position).length()
			
			if orb_dist > 500 and special_cooldown < 0:
				special_cooldown = 3
				attacking = true
				play_animation("Special")
				
			elif orb_dist > 50:
				attack_cooldown = smack_recharge*1.5
				smack_orbs(GameManager.player.global_position)
				
		elif aim_direction.length() < 400:
			attack_cooldown = smack_recharge
			attacking = true
			play_animation("Attack")
			
			
func launch_orbs():
	var delta_angle = PI/12*(num_orbs-1)
	var angle = -delta_angle/2*(num_orbs-1)
	for i in range(num_orbs):
		orbs[i] = death_orb.instance().duplicate()
		var orb = orbs[i]
		orb.global_position = global_position + (Vector2(-20, 0) if facing_left else Vector2(20, 0))
		orb.velocity = aim_direction.normalized().rotated(angle) * smack_speed * 0.7
		orb.source = self
		orb.scale = Vector2.ONE*4*orb_size
		orb.mass = 3*orb_size
		orb.damage_mult = orb_damage_mult
		orb.get_node('CollisionShape2D').scale = Vector2.ONE/orb_size
		GameManager.projectiles_node.add_child(orb)
		angle += delta_angle
		
	if is_player:
		GameManager.camera.set_trauma(0.5)
		
	if precision_mode:
		orbs_are_accelerating = true
	
func smack_orbs(target_pos):
	for i in range(num_orbs):
		if is_instance_valid(orbs[i]):
			var smack_dir = (target_pos - orbs[i].global_position).normalized()
			var side = -sign(smack_dir.x)
			var offset = Vector2(20*side, 0*smack_dir.y)
			stands[i].conjure(orbs[i].global_position + offset + orbs[i].velocity*0.1, -side)
			stands[i].next_smack_vel = smack_dir*max(smack_speed, orbs[i].velocity.length()*1.1)*(0.95 + randf()*0.1)
	
	if is_player:
		GameManager.camera.set_trauma(0.4)
		
func accelerate_orbs(target_pos, delta):
	var accel = smack_speed*2*delta
	var offset = (target_pos - global_position).normalized().rotated(PI/2)*5*(num_orbs+1) if num_orbs > 1 else Vector2.ZERO
	var offset_delta_angle = PI*2/num_orbs
	
	for i in range(num_orbs):
		if is_instance_valid(orbs[i]):
			var orb = orbs[i]
			var init_vel = orb.velocity
			var current_speed = orb.velocity.length()
			
			offset = offset.rotated(offset_delta_angle)
			var target_dir = (target_pos - orb.global_position + offset)
			var current_dir = orb.velocity/current_speed
			var delta_angle = 0
			if current_speed > 50:
				var diff_angle = current_dir.angle_to(target_dir)
				delta_angle = min(abs(diff_angle), PI*accel/400)
				accel *= min(1.5 - 3*abs(diff_angle)/PI, 1) 
				current_dir = current_dir.rotated(delta_angle*sign(diff_angle))
			else:
				current_dir = target_dir.normalized()
			
			current_speed = clamp(current_speed + accel, 0, smack_speed*min(target_dir.length()/50, 1))
			orb.velocity = current_dir*current_speed
			
			var delta_vel = orb.velocity - init_vel*0.5
			var delta_speed = max(delta_vel.length(), 0.0001)
			stands[i].conjure(orb.global_position - (delta_vel/delta_speed)*(15 + orb_size*15 - delta_angle*30), sign(delta_vel.x), false)
			
func decelerate_orbs():
	for i in range(num_orbs):
		if is_instance_valid(orbs[i]):
			var current_speed = max(orbs[i].velocity.length(), 0.01)
			stands[i].set_pos(orbs[i].global_position + (orbs[i].velocity/current_speed)*(30*orb_size - current_speed*0.05), -sign(orbs[i].velocity.x))
			orbs[i].velocity *= 0.9
			
func area_attack():
	Violence.melee_attack(self, attack_collider, 20, 300, 1)
	if is_player:
		GameManager.camera.set_trauma(0.5)
	
func detonate_orbs():
	orb_detonate_audio.play()
	for i in range(num_orbs):
		if is_instance_valid(orbs[i]):
			orbs[i].detonate()
			orbs[i] = null
			
func is_any_orb_valid():
	for orb in orbs:
		if is_instance_valid(orb):
			return true	
	return false
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Attack" or anim_name == "Special":
		attacking = false
		lock_aim = false
		
	elif anim_name == "Die":
		detonate_orbs()
		if is_in_group("enemy"):
			actually_die()
