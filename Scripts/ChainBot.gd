extends "res://Scripts/Enemy.gd"

onready var attack_collider = $AttackCollider/CollisionShape2D

var num_pellets = 6
var shot_speed = 150
var walk_speed = 160

var charging = false
var charge_level = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	health = 150
	max_speed = walk_speed
	bullet_spawn_offset = 20
	flip_offset = 0
	score = 100
	init_healthbar()

func _process(delta):
	if charging:
		charge_level += delta
		
	attack_collider.position.x = -34 if facing_left else 34

func player_action():
	aim_direction.y = 0
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		charging = true
		attacking = true
		lock_aim = true
		max_speed = 20
		charge_level = 0.3
		animplayer.play("Charge")
		
	elif Input.is_action_just_released("attack1") and charging:
		attack()
	
func attack():
	charging = false
	attack_cooldown = 1
	animplayer.play("Attack")
	

func swing_attack():
	num_pellets = int(6*charge_level)
	var spread = 120*charge_level
	var dir = Vector2(1, 0)
	var angle = -spread/2
	var delta_angle = spread/(num_pellets)
	
	if facing_left:
		angle *= -1
		delta_angle *= -1
		dir.x *= -1

	for i in num_pellets + 1:
		var pellet_dir = dir.rotated(deg2rad(angle))
		angle += delta_angle
		var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
		shoot_bullet(pellet_dir*pellet_speed, 10, 2, 1)
		
	melee_attack(attack_collider, 30*charge_level, 300*charge_level, 2 if charge_level > 1 else 1)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Charge":
		attack()
	elif anim_name == "Attack":
		attacking = false
		lock_aim = false
		max_speed = walk_speed
		
	elif anim_name == "Die":
		queue_free()
		
