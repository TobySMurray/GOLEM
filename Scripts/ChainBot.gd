extends "res://Scripts/Enemy.gd"

var num_pellets = 6
# Called when the node enters the scene tree for the first time.
func _ready():
	max_speed = 100
	bullet_spawn_offset = 12
	flip_offset = 0

func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		attack()
		
func attack():
	attacking = true
	attack_cooldown = 150
	animplayer.play("Attack")
	var angle = 0
	for i in num_pellets:
		var pellet_direction = aim_direction.x.rotated(angle)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Attack":
		attacking = false
