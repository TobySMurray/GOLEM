extends "res://Scripts/Enemy.gd"

onready var attack_fx = $AttackFX

var walk_speed = 140
var charging = false
var charge_timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	max_speed = walk_speed
	flip_offset = -23
	pass # Replace with function body.
	
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Ready":
		animplayer.play("Charge")
		
	elif anim_name == "Attack" or anim_name == "Special":
		attacking = false
		lock_aim = false
		max_speed = walk_speed
