extends "res://Scripts/Enemy.gd"

onready var muzzle_flash = $MuzzleFlash
onready var audio = $AudioStreamPlayer2D
onready var reload = $Reload

var shot_speed = 150
var shot_spread = 15
var num_pellets = 6

var max_range = 250
var ai_can_shoot = false
var ai_move_timer = 0
var ai_shoot_timer = 0
var ai_target_point = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 75
	max_speed = 120
	bullet_spawn_offset = 10
	flip_offset = -53
	healthbar.max_value = health
	init_healthbar()
	score = 50
	
func _process(delta):
	ai_move_timer -= delta
	
func _physics_process(delta):
	if invincible:
		modulate = Color(1,0,0,1)
	if !invincible:
		modulate = Color(1,1,1,1)
	
func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		shoot()
		
func ai_move():
	var to_player = GameManager.player.shape.position - shape.global_position
	if to_player.length() > max_range:
		ai_can_shoot = false
		ai_move_timer = -1
		target_velocity = astar.get_astar_target_velocity(shape.global_position, GameManager.player.shape.position)
	else:
		ai_can_shoot = true
		
		if ai_move_timer < 0:
			ai_move_timer = 0.7 + randf()
			if randf() < 0.5:
				ai_target_point = shape.global_position + Vector2(randf()-0.5, randf()-0.5)*150
		
		var to_target_point = ai_target_point - global_position
		if to_target_point.length() > 5:
			target_velocity = to_target_point
		else:
			ai_target_point = global_position
			target_velocity = Vector2.ZERO
		
		
		
func ai_action():
	aim_direction = (GameManager.player.global_position - global_position).normalized()
	if ai_can_shoot and attack_cooldown < 0:
		shoot()
		attack_cooldown = 2
		
func shoot():
	attacking = true
	attack_cooldown = 1.2
	animplayer.play("Shoot")
	show_muzzle_flash()
	
	velocity -= aim_direction*180
	
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
		actually_die()


func _on_Timer_timeout():
	invincible = false
