extends Host
class_name Enemylike

const score_popup = preload("res://Scenes/ScorePopup.tscn")

onready var animplayer = $AnimationPlayer
onready var sprite = $Sprite
var swap_shield

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

var override_speed = null
var override_accel = null

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

func _ready():
	swap_shield = get_node_or_null('EnemyFX/ClearMoon')
	if not swap_shield:
		swap_shield = get_node_or_null('ClearMoon')
		
func physics_process(delta):
	if dead and is_player:
		death_timer -= delta
		if death_timer < 0:
			death_timer = 99999999
			actually_die()

func move(delta):
	var cur_speed = override_speed if override_speed != null else max_speed
	var cur_accel = override_accel if override_accel != null else accel
	velocity = lerp(velocity, target_velocity.normalized()*cur_speed, cur_accel*delta)	
	velocity = move_and_slide(velocity)
	
func play_animation(anim):
	if not dead:
		animplayer.play(anim)
	
func take_damage(damage, source, stun = 0):
	pass
	
func is_invincible():
	return invincible or invincibility_timer > 0
	
func die():
	if dead: return
	
	dead = true
	invincible = true
	target_velocity = Vector2.ZERO
	death_timer = 0.5
	animplayer.play("Die")
	
func actually_die():
	if not is_player:
		queue_free()
	else:
		dead = true
		GameManager.game_over()
	

