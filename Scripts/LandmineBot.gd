extends "res://Scripts/Enemy.gd"


func _ready():
	max_speed = 50
	flip_offset = -6
	attacking = false

func player_action():
	if Input.is_action_just_pressed("attack1") and not attacking:
		attacking = true
		lock_aim = true
		max_speed = 0
		attack_cooldown = 4
		bury()
		
	if Input.is_action_just_pressed("attack2") and animplayer.current_animation == "BuryIdle":
		animplayer.play("Undig")
		
	if Input.is_action_just_pressed("attack1") and animplayer.current_animation == "BuryIdle":
		animplayer.play("Explode")

func bury():
	animplayer.play("Dig")
	


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Dig" and attacking:
		animplayer.play("BuryIdle")
	if anim_name == "Undig":
		max_speed = 100 
		attacking = false
		lock_aim = false
