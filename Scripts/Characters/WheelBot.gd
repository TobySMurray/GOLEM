extends "res://Scripts/Enemy.gd"

const DustTrail = preload('res://Scenes/Particles/DustTrail.tscn')

onready var dash_fx = $DashFX
onready var audio = $AudioStreamPlayer2D
onready var dash_audio = $Dash
onready var charge_audio = $ChargeAudio
onready var movement_raycast = $RayCast2D
onready var aimbot_collider = $AimbotCollider
onready var aimbot_reticle = $AimbotReticle
onready var wheel_particles = $EnemyFX/FootsetpParticles

var walk_speed
var burst_size
var shot_speed
var reload_time

var walk_speed_levels = [250, 250, 275, 300, 333, 366, 400, 450]
var burst_size_levels = [3, 4, 5, 6, 8, 10, 12]
var shot_speed_levels = [200, 300, 400, 500, 550, 600, 666]

var killdozer_mode = false
var top_gear = false
var exhaust_blast = false
var charge_mode = false
var aimbot_mode = false

var burst_count = 0
var burst_timer = 0
var exhaust_timer = 0

var dash_start_point = Vector2.ZERO

var ai_target_point = Vector2.ZERO
var ai_retarget_timer = 0
var can_shoot = false

var aimbot_candidates = []
var aimbot_target = null

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.WHEEL
	max_health = 50
	mass = 0.75
	accel = 2.5
	bullet_spawn_offset = 10
	flip_offset = -71
	healthbar.max_value = health
	max_attack_cooldown = 1
	max_special_cooldown = 0.75
	score = 70
	init_healthbar()
	toggle_enhancement(false)
	
	remove_child(aimbot_reticle)
	GameManager.projectiles_node.add_child(aimbot_reticle)
	
func toggle_playerhood(state):
	if is_instance_valid(aimbot_reticle):
		aimbot_reticle.visible = false
	aimbot_mode = false
	.toggle_playerhood(state)

func toggle_enhancement(state):
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	shot_speed = shot_speed_levels[level]
	burst_size = burst_size_levels[level]
	reload_time = 1 if state else 1.6
	accel = 2.5
	killdozer_mode = false
	top_gear = false
	exhaust_blast = false
	charge_mode = false

	if state == true:
		if GameManager.player_upgrades['top_gear'] > 0:
			accel = 1.5
			max_speed *= 1.5
			top_gear = true
			
		if GameManager.player_upgrades['self-preservation_override'] > 0:
			killdozer_mode = true
			
		exhaust_blast = GameManager.player_upgrades['bypassed_muffler'] > 0
		
		charge_mode = GameManager.player_upgrades['manual_plasma_throttle'] > 0
		
		aimbot_mode = GameManager.player_upgrades['advanced_targeting'] > 0
			
	burst_count = 0
	movement_raycast.enabled = !state
	aimbot_collider.set_deferred('disabled', !aimbot_mode)
	.toggle_enhancement(state)

func misc_update(delta):
	ai_retarget_timer -= delta
	
	if burst_count > 0:
		burst_timer -= delta
		if charge_mode:
			charge_audio.pitch_scale = 3.8 - burst_timer
			
		if burst_timer < 0:
			shoot()
	else:
		lock_aim = false
		lock_aim = false
		
	if aimbot_mode:
		aimbot_collider.rotation = aim_direction.angle()
		
		var mouse_pos = get_global_mouse_position()
		var min_dist = 9999999
		aimbot_target == null
		for enemy in aimbot_candidates:
			if is_instance_valid(enemy):
				var dist = (enemy.global_position - mouse_pos).length()
				if dist < min_dist:
					aimbot_target = enemy
					min_dist = dist
		
				
		if is_instance_valid(aimbot_target):
			aimbot_reticle.visible = true
			aimbot_reticle.global_position = aimbot_target.global_position
		else:
			aimbot_reticle.visible = false
			
	if exhaust_blast:
		var speed = velocity.length()
		if speed > 100:
			exhaust_timer -= delta*(speed/100.0)
			if exhaust_timer < 0:
				exhaust_timer = 0.35
				Violence.shoot_bullet(self, global_position, -velocity.rotated(PI/6*(randf()-0.5)), 5, 0.25, 1.5, 'flame')
		
	
func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		start_burst()
		
	elif charge_mode and Input.is_action_just_released('attack1') and burst_count > 0 and not dead:
		shoot()
	
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0:
		special_cooldown = max_special_cooldown
		dash()
		
func ai_move():
	var player_dist = (GameManager.player.global_position - global_position).length()
	can_shoot = player_dist < 300
	
	if player_dist < 400:
		if (ai_target_point - global_position).length_squared() < 225 or movement_raycast.is_colliding() or ai_retarget_timer < 0:
			ai_retarget_timer = 3
			var from_player = global_position - GameManager.player.global_position 
			var retarget_angle
			if randf() < 0.25:
				retarget_angle = from_player.angle() - PI + (randf()-0.5)*PI
			else:
				retarget_angle = from_player.angle() + randf()*PI/2*sign(from_player.cross(velocity))
				
			ai_target_point = GameManager.player.global_position + 150*Vector2(cos(retarget_angle), sin(retarget_angle))
			
			#var col = get_world_2d().direct_space_state.intersect_ray(global_position + foot_offset, ai_target_point + foot_offset, [self], collision_mask)
			#if col and (col['position'] - global_position).length_squared() < 400:
			#	ai_retarget_timer = -1
				
		target_velocity = ai_target_point - global_position
		movement_raycast.cast_to = target_velocity.normalized()*20
				
	else:
		target_velocity = Vector2.ZERO
		#target_velocity = astar.get_astar_target_velocity(global_position + foot_offset, GameManager.player.global_position)


func ai_action():
	if not lock_aim:
		aim_direction = (GameManager.player.global_position - global_position).normalized()
		
	if attack_cooldown < 0 and can_shoot:
		start_burst()
	
func start_burst():
	if not charge_mode:
		attack_cooldown = reload_time
		burst_count = burst_size
		burst_timer = -1
		shoot()
	else:
		burst_count = 1
		burst_timer = 2.0
		attacking = true
		charge_audio.play()
		#play_animation('Charge')
	
	
func shoot():
	audio.play()
	play_animation("Attack")
	animplayer.seek(0)
	burst_count -= 1
	attacking = true
	charge_audio.stop()
	
	if is_player:
		GameManager.camera.set_trauma(0.3)
	
	var bullet_speed = shot_speed
	var power
	if charge_mode:
		power = 0.15 + (2.0 - burst_timer)
		bullet_speed *= (1.0 + power)
		
	var bullet_vel
	if aimbot_mode and is_instance_valid(aimbot_target):
			
		var a = bullet_speed*bullet_speed - aimbot_target.velocity.length_squared()
		var b = 2*(global_position - aimbot_target.global_position).dot(aimbot_target.velocity)
		var c = -(global_position - aimbot_target.global_position).length_squared()
		var sqrt_bit = b*b - 4*a*c
		if sqrt_bit >= 0:
			sqrt_bit = sqrt(sqrt_bit)
			var t = [(-b + sqrt_bit)/(2*a), (-b - sqrt_bit)/(2*a)]
			if t[0] > 0 and t[1] > 0:
				t = min(t[0], t[1])
			else:
				t = max(t[0], t[1])
			var impact_point = aimbot_target.global_position + aimbot_target.velocity*t
			aim_direction = (impact_point - global_position).normalized()
			
		bullet_vel = aim_direction*bullet_speed
	else:
		bullet_vel = aim_direction*bullet_speed + velocity/2
	
	if not charge_mode:
		velocity -= aim_direction*30
		shoot_bullet(bullet_vel, 10)
		burst_timer = 0.45/burst_size
	else:
		velocity -= aim_direction*70*sqrt(burst_size)*pow(power, 2)
		var size = 0.5 + power*1.5
		shoot_bullet(bullet_vel, 10*(power*burst_size), 0.15*power*burst_size, 5, 'pellet', 0, Vector2(size, size))
	
func dash():
	if dead: return
	
	var dash_dir = aim_direction.normalized()
	var dash_end_point = global_position + 83*dash_dir
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position + foot_offset, dash_end_point + foot_offset, [self], collision_mask)
	if result:
		dash_end_point = result['position'] - foot_offset
		
	var dust_trail = DustTrail.instance().duplicate()
	dust_trail.global_position = (0.9*global_position + 1.1*dash_end_point)/2 - Vector2.UP*10
	dust_trail.process_material.emission_box_extents.x = (dash_end_point - global_position).length()*0.6
	dust_trail.rotation = dash_dir.angle()
	dust_trail.process_material.direction.y = 1 if abs(dust_trail.rotation) > PI/2 else -1
	dust_trail.emitting = true
	GameManager.projectiles_node.add_child(dust_trail)
	
	var maintained_speed = walk_speed if top_gear else 150	
	if killdozer_mode:
		for offset in [Vector2(0, 7), Vector2(0, -7)]:
			result = space_state.intersect_ray(global_position + offset + dash_dir*20, dash_end_point, [self], 4, false, true)
			if result and result['collider'].is_in_group('hitbox'):
				dash_end_point = result['position'] - offset - (dash_end_point - global_position).normalized()*10
				maintained_speed = walk_speed/2.1
				break
				
	if exhaust_blast:
		for i in range(4 + burst_size/2):
			var dir = -dash_dir.rotated((0.5 - randf())*PI/8)
			var speed = walk_speed*(1.5 + randf())
			shoot_bullet(speed*dir, 10, 0.3, 2, 'flame')
	
	attacking = false
	#burst_count = 0
	lock_aim = true
	
	velocity = maintained_speed*dash_dir
	
	dash_start_point = global_position + Vector2((-70 if aim_direction.x < 0 else 0), 0)
	global_position = dash_end_point
	#set_dash_fx_position()
	
	dash_audio.play()
	#dash_fx.frame = 0
	#dash_fx.flip_h = aim_direction.x < 0
	#dash_fx.play("Swoosh")
	
	aim_direction.x *= -1

func _on_Hitbox_area_entered(area):
	if killdozer_mode and area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if entity.is_in_group('enemylike') and not entity.invincible:
			var rel_speed = (velocity - entity.velocity).length()
			var damage = pow(rel_speed, 0.65) * (2 if rel_speed > walk_speed/2 else 1)
			entity.take_damage(damage, self)
			
			var new_vel = (global_position - entity.global_position).normalized() * velocity.length()
			var delta_vel = new_vel - velocity
			velocity = new_vel*0.7
			entity.velocity -= delta_vel*2/entity.mass
			
			if rel_speed > 100:
				if rel_speed < walk_speed*0.9:
					GameManager.set_timescale(0.9 - rel_speed/walk_speed)
				else:
					GameManager.set_timescale(0.01, clamp(2*(rel_speed/walk_speed - 0.9), 0, 0.5))
				take_damage(3, entity)
			
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (-delta_vel).angle(), sqrt(delta_vel.length())*30, damage, 30)
		
	
func set_dash_fx_position():
	dash_fx.global_position = dash_start_point

func take_damage(damage, source, stun = 0):
	.take_damage(damage, source, stun)
	if not is_player and stun == 0 and not immobile and not dead and special_cooldown < 0 and randf() < 0.5:
		special_cooldown = 4
		aim_direction = velocity
		call_deferred('dash')
	

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Attack":
		attacking = false
	if anim_name == "Die":
		aimbot_reticle.queue_free()
		if is_in_group("enemy"):
			actually_die()


func _on_AimbotCollider_area_entered(area):
	if area.is_in_group('hitbox') and area.get_parent().is_in_group('enemy') and area.get_parent() != self:
		aimbot_candidates.append(area.get_parent())


func _on_AimbotCollider_area_exited(area):
	if area.is_in_group('hitbox') and area.get_parent().is_in_group('enemy') and area.get_parent() != self:
		aimbot_candidates.erase(area.get_parent())
