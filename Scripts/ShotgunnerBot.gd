extends "res://Scripts/Enemy.gd"

onready var muzzle_flash = $MuzzleFlash
onready var audio = $StepAudio
onready var reload = $Reload

var shot_speed
var num_pellets
var reload_time

var walk_speed_level = [110, 120, 130, 140, 150, 160, 170]
var shot_speed_level = [175, 250, 325, 400, 475, 550, 600]
var num_pellets_level = [6, 6, 7, 8, 9, 10, 12, 14]
var reload_time_level = [1.33, 1.2, 1.1, 1, 0.95, 0.9, 0.85]
var shot_spread = 15

var max_range = 250
var ai_can_shoot = false
var ai_move_timer = 0
var ai_shoot_timer = 0
var ai_target_point = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = "shotgun"
	health = 75
	max_speed = 120
	bullet_spawn_offset = 10
	flip_offset = -53
	healthbar.max_value = health
	init_healthbar()
	score = 50
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	max_speed = walk_speed_level[level]
	shot_speed = shot_speed_level[level]
	num_pellets = num_pellets_level[level]
	reload_time = reload_time_level[level]
	max_attack_cooldown = reload_time
	
	
func misc_update(delta):
	ai_move_timer -= delta
	
func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		shoot()
		
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
		attack_cooldown = reload_time*1.5
		
func shoot():
	attacking = true
	attack_cooldown = reload_time
	animplayer.play("Shoot")
	show_muzzle_flash()
	
	velocity -= aim_direction*180
	
	if is_in_group("player"):
		GameManager.camera.set_trauma(0.55, 5)
	
	for i in range(num_pellets):
		var pellet_dir = aim_direction.rotated((randf()-0.5)*deg2rad(shot_spread))
		var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5)) + (100 if is_in_group("player") else 0)
		shoot_bullet(pellet_dir*pellet_speed, 10, 0.3, 4)
			
func show_muzzle_flash():
	muzzle_flash.rotation = aim_direction.angle();
	muzzle_flash.show_behind_parent = muzzle_flash.rotation_degrees < -30 and muzzle_flash.rotation_degrees > -150
	muzzle_flash.frame = 0
	muzzle_flash.play("Flash")
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Shoot":
		attacking = false
		reload.play()
	elif anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()


func _on_Timer_timeout():
	invincible = false
