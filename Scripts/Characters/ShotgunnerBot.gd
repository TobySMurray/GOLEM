extends "res://Scripts/Enemy.gd"

onready var muzzle_flash = $MuzzleFlash
onready var audio = $StepAudio
onready var gun_audio = $GunAudio
onready var reload = $Reload
onready var melee_collider = $MeleeCollider/CollisionShape2D

var shot_speed
var num_pellets
var bash_damage

var walk_speed_level = [110, 120, 130, 140, 150, 160, 170]
var shot_speed_level = [175, 350, 425, 500, 575, 650, 700]
var num_pellets_level = [6, 6, 7, 8, 9, 10, 12, 14]
var reload_time_level = [1.33, 1.2, 1.1, 1, 0.95, 0.9, 0.85]
var bash_damage_level = [20, 20, 25, 30, 35, 40, 45]

var num_shells = 1
var bullet_spread = 15
var bullet_kb = 0.3
var bullet_type = 'pellet'
var recoil = 180
var melee_stun = 0
var full_auto = false
var flak_mode = false

var max_range = 250
var ai_can_shoot = false
var ai_move_timer = 0
var ai_shoot_timer = 0
var ai_target_point = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.SHOTGUN
	max_health = 75
	bullet_spawn_offset = 10
	flip_offset = -53
	max_special_cooldown = 1.2
	healthbar.max_value = health
	attack_cooldown_audio = load('res://Sounds/SoundEffects/ShotgunReloadLight.wav')
	attack_cooldown_audio_preempt = 0.2
	init_healthbar()
	score = 50
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	max_speed = walk_speed_level[level]
	shot_speed = shot_speed_level[level]
	num_pellets = num_pellets_level[level]
	max_attack_cooldown = reload_time_level[level]
	bash_damage = bash_damage_level[level]
	
	num_shells = 1
	bullet_type = 'pellet'
	bullet_kb = 0.3
	melee_stun = 0
	recoil = 180
	full_auto = false
	flak_mode = false
	
	if state == true:
		if GameManager.player_upgrades['induction_barrel'] > 0:
			bullet_type = 'flame'
			bullet_kb = 0.15
		
		max_attack_cooldown *= 1.0 + 0.5*GameManager.player_upgrades['stacked_shells']
		bullet_spread = 15*(1.0 + GameManager.player_upgrades['stacked_shells'])
		num_shells *= 1 + GameManager.player_upgrades['stacked_shells']
		recoil *= 1.0 + 1.5*GameManager.player_upgrades['stacked_shells']
		
		melee_stun = 1.5*GameManager.player_upgrades['shock_stock']
		
		if GameManager.player_upgrades['soldering_fingers'] > 0:
			flak_mode = true
			bullet_spread /= 5
		
		full_auto = GameManager.player_upgrades['reload_coroutine'] > 0
		for i in range(GameManager.player_upgrades['reload_coroutine']):
			max_attack_cooldown *= 0.8
	
	.toggle_enhancement(state)
	
func misc_update(delta):
	ai_move_timer -= delta
	melee_collider.position.x = -15 if facing_left else 15
	
func player_action():
	if (Input.is_action_just_pressed("attack1") or (full_auto and Input.is_action_pressed("attack1"))) and not attacking and attack_cooldown < 0:
		shoot()
		
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0:
		start_bash()
			
func ai_move():
	var to_player = GameManager.player.global_position - shape.global_position
	var player_dist = to_player.length()
	
	if player_dist > 350:
		target_velocity = Vector2.ZERO
		
	if to_player.length() > 300:
		ai_can_shoot = false
		ai_move_timer = -1
		target_velocity = to_player  #astar.get_astar_target_velocity(shape.global_position, GameManager.player.shape.global_position)
	else:
		ai_can_shoot = true
		
		if ai_move_timer < 0:
			ai_move_timer = 0.7 + randf()
			if randf() < 0.5:
				ai_target_point = shape.global_position + Vector2(randf()-0.5, randf()-0.5)*150
		
		var to_target_point = ai_target_point - shape.global_position
		if to_target_point.length() > 5:
			target_velocity = to_target_point
		else:
			ai_target_point = shape.global_position
			target_velocity = Vector2.ZERO
		
func ai_action():
	aim_direction = (GameManager.player.global_position - global_position).normalized()
	if ai_can_shoot and attack_cooldown < 0:
		shoot()
		attack_cooldown = max_attack_cooldown * 1.5
		
func shoot():
	gun_audio.play()
	attacking = true
	attack_cooldown = max_attack_cooldown
	play_animation("Shoot")
	show_muzzle_flash()
	
	velocity -= aim_direction*recoil
	
	if is_player:
		GameManager.camera.set_trauma(0.55, 5)
		
	if flak_mode:
		for i in range(num_shells):
			var dir = aim_direction.rotated((randf()-0.5)*deg2rad(bullet_spread))
			var speed = shot_speed * (1 + 0.2*(randf()-0.5))
			Violence.shoot_flak_bullet(self, global_position + aim_direction*bullet_spawn_offset, dir*speed, num_pellets*5, 1, 4, num_pellets*1.5, 10, shot_speed*0.66, bullet_type)
		
	else:
		for i in range(num_pellets*num_shells):
			var pellet_dir = aim_direction.rotated((randf()-0.5)*deg2rad(bullet_spread))
			var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
			shoot_bullet(pellet_dir*pellet_speed, 10, bullet_kb, 4, bullet_type)
			
func show_muzzle_flash():
	muzzle_flash.rotation = aim_direction.angle();
	muzzle_flash.show_behind_parent = muzzle_flash.rotation_degrees < -30 and muzzle_flash.rotation_degrees > -150
	muzzle_flash.frame = 0
	muzzle_flash.play("Flash")
	gun_particles.position.x = -13 if facing_left else 13
	gun_particles.rotation = muzzle_flash.rotation
	gun_particles.emitting = true
	
func start_bash():	
	attacking = true
	lock_aim = true
	special_cooldown = max_special_cooldown
	play_animation('Special')
	
	#Hakita bless
	var hits = Violence.melee_attack(self, melee_collider, 0, 0, 0, 0)
	for hit in hits:
		if hit.is_in_group('bullet') and hit.source == self:
			GameManager.set_timescale(0.001, 1, 100)
			hit.velocity = (hit.velocity.length()*2)*aim_direction.rotated((randf()-0.5)*PI/36)
			hit.damage *= 1.3
			hit.stun = melee_stun/2
			hit.modulate = Color.yellow
	
func bash():
	if is_player:
		GameManager.camera.set_trauma(0.4)
	velocity.x += 250*sign(aim_direction.x)
	Violence.melee_attack(self, melee_collider, bash_damage, 1000, 1, melee_stun)
	

	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Shoot":
		attacking = false
		#reload.play()
	elif anim_name == 'Special':
		attacking = false
		lock_aim = false
	elif anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()


func _on_Timer_timeout():
	invincible = false
