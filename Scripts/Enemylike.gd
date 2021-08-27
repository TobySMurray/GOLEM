extends Host
class_name Enemylike

const score_popup = preload("res://Scenes/ScorePopup.tscn")

onready var animplayer = $AnimationPlayer
onready var sprite = $Sprite
onready var swap_shield = get_node_or_null('ClearMoon')

export var max_health = 100
onready var health = float(max_health)
export var mass = 1.0
export var max_speed = 100
export var accel = 10.0
export var stun_resist = 0.0

var enemy_type = 8 #Stupid hack, can't reference Enemy.EnemyType in a superclass of Enemy. Will probably break later.

var velocity = Vector2.ZERO
var target_velocity = Vector2.ZERO
var aim_direction = Vector2.ZERO

var stunned = false
var stun_timer = 0

var invincible = false setget , is_invincible
var invincibility_timer = 0

var damage_flash = false
var damage_flash_timer = 0

var facing_left = true
var flip_offset = 0

var dead = false
var death_timer = 0


func play_animation(anim):
	if not dead:
		animplayer.play(anim)

func move(delta):
	pass
	
func take_damage(damage, source, stun = 0):
	pass
	
func is_invincible():
	return invincible or invincibility_timer > 0
	
func die():
	pass
	

