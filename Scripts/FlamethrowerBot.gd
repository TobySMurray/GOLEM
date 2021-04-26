extends "res://Scripts/Enemy.gd"

var num_pellets = 5

var shot_spread = 15
var shot_speed = 175
var walk_speed = 120

var fuel = 200
var shot_timer = 0
var flamethrowing = false

onready var flamethrower = $Flamethrower

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 150
	max_speed = walk_speed
	bullet_spawn_offset = 10
	flip_offset = -46
	healthbar.max_value = health
	score = 75
	init_healthbar()

func player_action():
	aim_direction.y = 0
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		attacking = true
		lock_aim = true
		max_speed = 20
		animplayer.play("Charge")
		flamethrower.play()
	if Input.is_action_just_released("attack1"):
		flamethrowing = false
		animplayer.play("Cooldown")
		

func _physics_process(delta):
	if flamethrowing and fuel > 0:
		fuel -= 1
		
		shot_timer -= delta
		if shot_timer < 0:
			flamethrower()
			
	elif not attacking and fuel < 200:
		fuel += 2
		
	if fuel <= 0:
		flamethrowing = false
		animplayer.play("Cooldown")
		flamethrower.stop()
		attack_cooldown = 1

func attack():
	animplayer.play("Attack")
	shot_timer = -1
	flamethrowing = true
	
func flamethrower():
	flamethrower.play(0.5)
	var pellets = max(fuel/50, 1)
	shot_timer = 40.0/(fuel+200)
	for i in range(pellets):
		var pellet_dir = aim_direction.rotated((randf()-0.5)*deg2rad(shot_spread))
		var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
		shoot_bullet(pellet_dir*pellet_speed, 3, 0, 0.5)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Charge":
		attack()
	if anim_name == "Cooldown":
		attacking = false
		lock_aim = false
		max_speed = 100
	elif anim_name == "Die":
		queue_free()
