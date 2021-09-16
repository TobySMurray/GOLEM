extends "res://Scripts/Enemy.gd"

onready var GasCloud = load('res://Scenes/GasCloud.tscn')

var num_pellets = 5

var walk_speed
var shot_spread
var shot_speed 
var fire_volume


var walk_speed_levels = [100, 115, 130, 145, 160, 175, 190]
var shot_speed_levels = [200, 200, 220, 240, 260, 280, 310]
var shot_spread_levels = [25, 15, 20, 25, 30, 40, 50]
var fire_volume_levels = [4, 4.8, 5.6, 6.2, 8,4, 9.6, 11.2]

var startup_lag = 0.5
var pressure_dropoff = 0.3
var startup_spurt = false
var recoil = 0
var speed_while_attacking = 40 
var thermobaric_mode = false
var nuclear_suicide = false

var pressure = 1
var shot_timer = 0
var flamethrowing = false
var last_clouds = []
var ai_shoot = false
var ai_shoot_timer = 0
var ai_target_point = Vector2.ZERO
var ai_retarget_timer = 0
var killed_by_player = false

onready var flamethrower_audio = $Flamethrower


# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.FLAME
	max_health = 110
	mass = 1.25
	bullet_spawn_offset = 10
	flip_offset = -46
	max_attack_cooldown = 1
	score = 50
	attack_cooldown_audio = load('res://Sounds/SoundEffects/FlameReload.wav')
	init_healthbar()
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	shot_speed = shot_speed_levels[level]
	shot_spread = shot_spread_levels[level]
	fire_volume = fire_volume_levels[level]
	startup_lag = 0.5 - 0.03*level
	pressure_dropoff = 0.3
	startup_spurt = false
	recoil = 0
	speed_while_attacking = 40
	thermobaric_mode = false
	nuclear_suicide = false
	
	if state == true:
		fire_volume *= 1.0 + 0.2*GameManager.player_upgrades['pressurized_hose']
		pressure_dropoff *= 1.0 + 0.4*GameManager.player_upgrades['pressurized_hose'] 
		for i in range(GameManager.player_upgrades['pressurized_hose']):
			startup_spurt = true
			startup_lag *= 0.5
			
		speed_while_attacking *= min(walk_speed, 1.0 + 0.75*GameManager.player_upgrades['optimized_regulator'])
		for i in range(GameManager.player_upgrades['optimized_regulator']):
			fire_volume *= 0.85
			pressure_dropoff *= 0.5
			
		if GameManager.player_upgrades['internal_combustion'] > 0:
			shot_speed *= 2
			shot_spread = 10
			recoil = 500
			
		thermobaric_mode = GameManager.player_upgrades['ultrasonic_nozzle'] > 0
			
		nuclear_suicide = GameManager.player_upgrades['aerated_fuel_tanks'] > 0
		
		if flamethrowing:
			stop_attacking()
			attack_cooldown = 0
			
	.toggle_enhancement(state)
			
			
func misc_update(delta):
	ai_retarget_timer -= delta
	ai_shoot_timer -= delta
	
	if flamethrowing and pressure > 0:
		pressure -= delta*pressure_dropoff
		velocity -= aim_direction.normalized() * recoil * pressure * delta
		
		shot_timer -= delta
		if shot_timer < 0:
			flamethrower()
			
	elif not attacking:
		pressure = 1.0
		
	if pressure <= 0:
		stop_attacking()


func player_action():
	if Input.is_action_pressed("attack1") and not attacking and attack_cooldown < 0:
		attacking = true
		attack()
	if Input.is_action_just_released("attack1") and attacking:
		stop_attacking()
		attack_cooldown = 0.8
		
	if Input.is_action_just_pressed("attack2") and GameManager.can_swap:
		die()
		GameManager.camera.trauma = 0.2
		GameManager.swap_bar.threshold_death_penalty = 0
	
func ai_move():
	if not lock_aim:
		aim_direction = (GameManager.player.global_position - global_position).normalized()
		
	var target_position = get_target_position()
	var target_dist = (target_position - global_position).length()
	
	if target_dist > 300:
		target_position = global_position
	
	else:
		target_velocity = target_position - global_position
		
	if target_dist < shot_speed*0.6 or ai_shoot_timer > 0:
		if attack_cooldown < 0 and !ai_shoot:
			ai_shoot = true
			ai_shoot_timer = 2
			attack()
		elif attack_cooldown > 0 and ai_shoot:
			attack_cooldown = 1
			ai_shoot = false
			
	elif ai_shoot:
		ai_shoot = false
		stop_attacking()

func attack():
	attacking = true
	override_speed = speed_while_attacking
	shot_timer = -1
	if is_player:
		animplayer.playback_speed = 0.5 / startup_lag
		if recoil > 0:
			accel = 3
	play_animation("Charge")
	flamethrower_audio.play()
	
func stop_attacking():
	flamethrowing = false
	attack_cooldown = 1
	if is_player:
		animplayer.playback_speed = 0.5 / startup_lag
	play_animation("Cooldown")
	flamethrower_audio.stop()
	
func flamethrower():
	flamethrower_audio.play(0.5)
	
	var limited_aim_direction = Util.limit_horizontal_angle(aim_direction, PI/6)
	var pellets = ceil(max(fire_volume*pressure, 1))
	var spread = shot_spread*(0.5 + pressure*0.5)
	if startup_spurt and pressure > 0.95:
		pellets *= 2
		spread = max(spread*2, 40)
	
	shot_timer = 0.2/(pressure+1)
	
	var clouds = []
	for i in range(pellets):
		var pellet_dir = limited_aim_direction.rotated((randf()-0.5)*deg2rad(spread))
		
		if thermobaric_mode:
			var pellet_speed = shot_speed * 0.9*(0.4 + 0.6*pressure) * (1 + 0.25*(randf()-0.5))
			clouds.append(shoot_gas_cloud(pellet_dir*pellet_speed*pressure))
		else:
			var pellet_speed = shot_speed * (0.7 + 0.3*pressure) * (1 + 0.5*(randf()-0.5))
			shoot_bullet(pellet_dir*pellet_speed, 5, 0, 0.6, "flame")
			
	if thermobaric_mode and len(clouds) > 0:
		clouds[0].next_in_chain = last_clouds
		last_clouds = clouds
					
func shoot_gas_cloud(vel):
	var cloud = GasCloud.instance().duplicate()
	cloud.global_position = global_position + Vector2(bullet_spawn_offset*(-1 if facing_left else 1), 0)
	cloud.source = self
	cloud.set_vel(vel)
	GameManager.projectiles_node.add_child(cloud)
	return cloud
	
func detonate_gas_clouds():
	for cloud in last_clouds:
		cloud.detonate(0.3)
	last_clouds = []


			
func get_target_position():
	var enemy_position = GameManager.player.global_position
	var target_position
	
	if health < 25:
		target_position = enemy_position
	else:
		#var enemy_tile_position = GameManager.ground.world_to_map(enemy_position)
		var target_tile_position
		if aim_direction.x > 0:
			target_tile_position = enemy_position - Vector2(2, 0)
		else:
			target_tile_position = enemy_position + Vector2(3, 0)
			
		target_position = target_tile_position
		target_position.y = enemy_position.y
		
	return target_position
	
func explode():
	if nuclear_suicide:
		GameManager.spawn_explosion(global_position, self, 2, 150, 800, 0, true)
		var offset = Vector2(60, 0)
		for i in range(6):
			GameManager.spawn_explosion(global_position + offset, self, 0.9, 80, 500, 0.25, true)
			offset = offset.rotated(PI/3)
		offset = Vector2(100, 0)
		for i in range(20):
			GameManager.spawn_explosion(global_position + offset, self, 0.5, 40, 300, 0.5, true)
			offset = offset.rotated(PI/10)	
	else:
		GameManager.spawn_explosion(global_position, self, 1, 60, 1000, 0, true)
		
func die(killer = null):
	.die(killer)
	if is_instance_valid(killer) and ((is_instance_valid(GameManager.player) and killer == GameManager.player) or (is_instance_valid(GameManager.true_player) and killer == GameManager.true_player)):
		killed_by_player = true

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Charge":
		play_animation("Attack")
		flamethrowing = true
		if is_player:
			animplayer.playback_speed = 1 + 0.1*GameManager.evolution_level
		else:
			animplayer.playback_speed = 1
			
	if anim_name == "Cooldown":
		attacking = false
		lock_aim = false
		override_speed = null
		accel = 10
		if is_player:
			animplayer.playback_speed = 1 + 0.1*GameManager.evolution_level
		else:
			animplayer.playback_speed = 1
		
		if thermobaric_mode:
			detonate_gas_clouds()
		
	if anim_name == "Die":
		detonate_gas_clouds()
		if is_in_group("enemy"):
			actually_die()

