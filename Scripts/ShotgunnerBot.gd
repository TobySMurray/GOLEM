extends "res://Scripts/Enemy.gd"

onready var muzzle_flash = $MuzzleFlash
onready var audio = $AudioStreamPlayer2D
onready var reload = $Reload

var shot_speed = 150
var shot_spread = 15
var num_pellets = 6
var max_range = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 120
	max_speed = 120
	bullet_spawn_offset = 10
	flip_offset = -53
	healthbar.max_value = health
	init_healthbar()
	
	
func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		shoot()
		
func ai_move():
	var to_player = GameManager.player.position - global_position
	#if to_player.length() > max_range:
		
		
func ai_action():
	aim_direction = (GameManager.player.global_position - global_position).normalized()
	if attack_cooldown < 0:
		shoot()
		
func shoot():
	attacking = true
	attack_cooldown = 1.2
	animplayer.play("Shoot")
	show_muzzle_flash()
	
	velocity -= aim_direction*180
	
	for i in range(num_pellets):
		var pellet_dir = aim_direction.rotated((randf()-0.5)*deg2rad(shot_spread))
		var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
		shoot_bullet(pellet_dir*pellet_speed, 10, 0.5, 3)
			
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
		queue_free()
