extends "res://Scripts/Enemy.gd"

var num_pellets = 5

var shot_spread = 15
var shot_speed = 100
var walk_speed = 100

var fuel = 200


# Called when the node enters the scene tree for the first time.
func _ready():
	bullet_spawn_offset = 10
	flip_offset = -46

func player_action():
	aim_direction.y = 0
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		fuel = 200
		attacking = true
		lock_aim = true
		max_speed = 0
		animplayer.play("Charge")
	if Input.is_action_just_released("attack1"):
		animplayer.play("Cooldown")
		

func _physics_process(delta):
	if fuel <= 0:
		animplayer.play("Cooldown")
	if attacking:
		fuel -= 1

func attack():
	attack_cooldown = 5
	animplayer.play("Attack")
	flamethrower()
	
func flamethrower():
	for i in range(num_pellets):
		if fuel > 0:
			var pellet_dir = aim_direction.rotated((randf()-0.5)*deg2rad(shot_spread))
			var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
			shoot_bullet(pellet_dir*pellet_speed, 10, 0.8)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Charge":
		attack()
	if anim_name == "Cooldown":
		attacking = false
		lock_aim = false
		max_speed = 100
