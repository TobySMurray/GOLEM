extends "res://Scripts/Enemy.gd"

onready var attack_fx = $AttackFX
onready var attack_beam = $AttackBeam
onready var raycast = $RayCast2D
onready var deflector_shape = $Deflector/CollisionShape2D

var walk_speed = 140
var charging = false
var charge_timer = 0
var raycast_endpoint = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 50
	max_speed = walk_speed
	flip_offset = -23
	init_healthbar()
	
func _process(delta):
	if charging:
		charge_timer -= delta
		if charge_timer < 0:
			release_attack()
	
func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		charge_attack()
	elif Input.is_action_just_pressed("attack2") and charging:
		charging = false
		animplayer.play("Special")
		
	raycast.cast_to = aim_direction*1000
	raycast_endpoint = raycast.get_collision_point() if raycast.is_colliding() else (global_position + aim_direction.normalized()*1000)
	
	
func charge_attack():
	attacking = true
	charging = true
	attack_cooldown = 3
	lock_aim = true
	max_speed = 0
	
	charge_timer = 2
	animplayer.play("Ready")
	
func release_attack():
	charging = false
	animplayer.play("Attack")
	
	attack_fx.flip_h = aim_direction.x < 0
	attack_fx.offset.x = -10 if attack_fx.flip_h else 7
	attack_fx.frame = 0
	attack_fx.play("Flash")
	
	var beam_length = (raycast_endpoint - global_position).length()
	var beam_dir = (raycast_endpoint - global_position)/beam_length
	
	attack_beam.rotation = aim_direction.angle()
	attack_beam.scale.x = beam_length/85

	var attack_anim = attack_beam.get_node("AnimatedSprite")
	attack_anim.frame = 0
	attack_anim.play("Shoot")
	
	melee_attack(attack_beam.get_node("CollisionShape2D"), 150, 500, 0)
	
	var dist = 50
	var delay = 0.05
	while dist < beam_length:
		var point = global_position + beam_dir*dist
		GameManager.spawn_explosion(point, 0.5, 20, 200, delay)
		dist += 50
		delay += 0.05
	
func area_attack():
	invincible = true
	melee_attack(deflector_shape, 20, 300, 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Ready":
		animplayer.play("Charge")
		
	elif anim_name == "Attack" or anim_name == "Special":
		attacking = false
		lock_aim = false
		invincible = false
		max_speed = walk_speed
		
	elif anim_name == "Die":
		queue_free()
