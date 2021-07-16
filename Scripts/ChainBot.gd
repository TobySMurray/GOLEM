extends "res://Scripts/Enemy.gd"

onready var attack_collider = $AttackCollider/CollisionShape2D
onready var audio = $AudioStreamPlayer2D


var num_pellets = 5
var walk_speed
var shot_speed
var charge_speed
var init_charge

var shot_speed_levels = [150, 175, 200, 225, 250, 275, 300]
var walk_speed_levels = [130, 160, 190, 220, 250, 270, 280]
var charge_speed_levels = [1, 1.4, 1.8, 2.2, 2.3, 2.4, 2.5]
var init_charge_levels = [0.3, 0.3, 0.3, 0.3, 0.5, 0.7, 1.0]

var kb_mult = 1
var damage_mult = 1
var melee_stun = 0
var laminar_shockwave = false
var speed_while_charging = 20
var footwork = false

var ai_state = 'approach'
var ai_side = 1
var ai_target_dist= 0
var ai_target_angle = 0
var ai_move_timer = 0
var ai_delay_timer = 0
var ai_charge_timer = 0
onready var ai_target_point = global_position

var charging = false
var charge_level = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = "chain"
	health = 100
	bullet_spawn_offset = 20
	flip_offset = 0
	score = 50
	init_healthbar()
	max_attack_cooldown = 1
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	shot_speed = shot_speed_levels[level]
	charge_speed = charge_speed_levels[level]
	init_charge = init_charge_levels[level]
	kb_mult = 1
	damage_mult = 1
	speed_while_charging = 20
	melee_stun = 0
	laminar_shockwave = true
	footwork = false
	
	if state == true:
		init_charge += charge_speed*0.33*GameManager.player_upgrades['precompressed_hydraulics']
		for i in range(GameManager.player_upgrades['precompressed_hydraulics']):
			charge_speed *= 0.8
		
		kb_mult -= min(0.95, 0.5*GameManager.player_upgrades['adaptive_wrists'])
		damage_mult += 0.2*GameManager.player_upgrades['adaptive_wrists']
		
		melee_stun = 2*GameManager.player_upgrades['discharge_flail']
		
		footwork = GameManager.player_upgrades['footwork_scheduler'] > 0
		speed_while_charging = max(20, GameManager.player_upgrades['footwork_scheduler']*walk_speed*0.4)
		
		var lminar_shockwave = GameManager.player_upgrades['vortex_technique'] > 0
		
		
	
	if charging:
		attack()
		
		
func misc_update(delta):
	ai_charge_timer -= delta
	ai_move_timer -= delta
	ai_delay_timer -= delta
	
	if charging:
		charge_level += delta*charge_speed
		
	attack_collider.position.x = -34 if facing_left else 34
	if facing_left:
		$Shadow.offset.x = -8
	if !facing_left:
		$Shadow.offset.x = 0

func player_action():
	aim_direction.y = 0
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		charge()
		
	elif Input.is_action_just_released("attack1") and charging:
		attack()
		
func ai_action():
	if not lock_aim:
		aim_direction = (GameManager.player.global_position - global_position).normalized()
	
	if charging and ai_charge_timer < 0:
		attack()
		
	
func ai_move():
	if ai_delay_timer < 0:
		var player_pos = GameManager.player.global_position
		var to_player = player_pos - global_position
		var side = 1 if to_player.x < 0 else -1
	
		match ai_state:
			'approach':
				if to_player.length() > 300:
					if ai_move_timer < 0:
						#target_velocity = astar.get_astar_target_velocity(global_position + foot_offset, player_pos)
						ai_move_timer = 0.5
				else:
					ai_move_timer = 2
					ai_target_point = null
					ai_state = ['start_attack', 'backstep'][int(randf()*2)]
						
			'start_attack':
				var to_point = player_pos + Vector2(20*side, 0) - global_position
				target_velocity = to_point
				
				if not charging and (ai_move_timer < 0 or (abs(to_point.x) < 5 and abs(to_point.y) < 20)):
					ai_charge_timer = 0.2 + randf()*0.5
					charge()
					ai_state = 'mid_attack'
					
			'mid_attack':
				target_velocity = player_pos + Vector2(20*side, 0) - global_position
				if not charging and not attacking:
					target_velocity = Vector2.ZERO
					ai_delay_timer = 0.1 + randf()*0.4
					ai_move_timer = 2 + ai_delay_timer
					ai_target_point = null
					ai_state = ['start_attack', 'backstep'][int(randf()*2)]
					
			'backstep':
				if ai_target_point == null:
					ai_target_point = player_pos + Vector2(120*side, 0).rotated(deg2rad((randf()-0.5) * 90))
					
				var to_point = ai_target_point - global_position
				target_velocity = to_point
				
				if ai_move_timer < 0 or to_point.length() < 5:
					ai_delay_timer = 0.1 + randf()*0.2
					ai_move_timer = 2 + ai_delay_timer
					ai_target_point = null
					ai_state = ['start_attack', 'backstep'][int(randf()*1.6)]

func charge():
	charging = true
	attacking = true
	lock_aim = !footwork
	max_speed = speed_while_charging
	charge_level = init_charge
	animplayer.play("Charge")
	
func attack():
	charging = false
	lock_aim = true
	attack_cooldown = 1
	animplayer.play("Attack")
	

func swing_attack():
	num_pellets = int(6*charge_level)
	var spread = 120*charge_level
	var dir = Vector2(1, 0)
	var angle = -spread/2
	var delta_angle = spread/(num_pellets)
	
	if is_in_group("player"):
		GameManager.camera.set_trauma(min(0.4 + charge_level*0.3, 1))
	
	if facing_left:
		angle *= -1
		delta_angle *= -1
		dir.x *= -1
		
	if footwork:
		velocity += dir*300 

	if laminar_shockwave:
		var size = min(1 + sqrt(num_pellets), 8)
		#var speed_mult = sqrt(num_pellets)*0.6
		var bullet = shoot_bullet(dir*shot_speed, 5*num_pellets, 2, 1.5, 'wave', Vector2(size*0.7, size))
		bullet.piercing = true
		
	else:
		for i in num_pellets + 1:
			var pellet_dir = dir.rotated(deg2rad(angle))
			angle += delta_angle
			var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
			shoot_bullet(pellet_dir*pellet_speed, 10, 0.5, 1, 'wave')
		
	melee_attack(attack_collider, 50*charge_level*damage_mult, 900*charge_level*kb_mult, charge_level+1, melee_stun*charge_level/charge_speed)
	if charge_level > 2:
		GameManager.spawn_explosion(global_position + Vector2((-20 if facing_left else 20), 0), self, 1, 10)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Charge":
		attack()
	elif anim_name == "Attack":
		attacking = false
		lock_aim = false
		max_speed = walk_speed
		
	elif anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()
		


func _on_Timer_timeout():
	invincible = false
