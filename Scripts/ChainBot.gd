extends "res://Scripts/Enemy.gd"

var num_pellets = 6
var shot_speed = 150
var walk_speed = 100
# Called when the node enters the scene tree for the first time.
func _ready():
	max_speed = 100
	bullet_spawn_offset = 20
	flip_offset = 0


func player_action():
	aim_direction.y = 0
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		attacking = true
		lock_aim = true
		max_speed = 0
		animplayer.play("Charge")
	
	
func attack():
	attack_cooldown = 2
	animplayer.play("Attack")
	

func swing_attack():
	var dir = Vector2(0,-1)
	var angle = 0
	var delta_angle = 0
	if facing_left:
		delta_angle = -30
	else:
		delta_angle = 30
	for i in num_pellets + 1:
		var pellet_dir = dir.rotated(deg2rad(angle))
		angle += delta_angle
		var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
		shoot_bullet(pellet_dir*pellet_speed, 10)
	

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Charge":
		attack()
	if anim_name == "Attack":
		attacking = false
		lock_aim = false
		max_speed = walk_speed
		
