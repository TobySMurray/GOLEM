extends "res://Scripts/Enemy.gd"

var burst_count = 0
var burst_timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	max_speed = 250
	accel = 3
	bullet_spawn_offset = 10
	flip_offset = -71
	
func _process(delta):
	if burst_count > 0:
		burst_timer -= delta
		if burst_timer < 0:
			shoot()
	else:
		lock_aim = false
	
func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		start_burst()
	
func start_burst():
	lock_aim = true
	attack_cooldown = 1
	burst_count = 3
	shoot()
	

func shoot():
	attacking = true
	animplayer.play("Attack")
	animplayer.seek(0)
	
	velocity -= aim_direction*30
	shoot_bullet(aim_direction*200 + velocity/2, 10)
	
	burst_timer = 0.15
	burst_count -= 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Attack":
		attacking = false
