extends "res://Scripts/Enemy.gd"

onready var attack_fx = $AttackFX
onready var attack_beam = $BeamRotator/AttackBeam
onready var sight_beam = $SightBeam
onready var raycast = $RayCast2D
onready var deflector_shape = $Deflector/CollisionShape2D


var walk_speed
var charge_time

var walk_speed_levels = [100, 110, 120, 130, 140, 150, 160]
var charge_time_levels = [1.5, 1.5, 1.2, 0.9, 0.8, 0.7, 0.6]

var speed_while_charging = 0
var beam_damage = 150
var beam_width = 1.0
var explosion_size = 0.5
var full_auto = false

var charging = false
var charge_timer = 0
var raycast_endpoint = Vector2.ZERO

onready var ai_target_point = global_position
var ai_move_timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = "archer"
	health = 70
	max_speed = walk_speed
	flip_offset = -23
	init_healthbar()
	score = 50
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	charge_time = charge_time_levels[level]
	speed_while_charging = 0
	beam_damage = 150
	beam_width = 1.0
	explosion_size = 0.5
	full_auto = false
	
	if state == true:
		speed_while_charging = 50*GameManager.player_upgrades['vibro-shimmy']
		
		for i in range(GameManager.player_upgrades['slobberknocker_protocol']):
			explosion_size += 0.2
			beam_width += 2
			beam_damage *= 1.5
		
		if GameManager.player_upgrades['half-draw'] > 0:
			full_auto = true
			explosion_size -= 0.5
			charge_time *= 0.5 +  0.1*GameManager.player_upgrades['slobberknocker_protocol'] 
			beam_damage = 50
			beam_width *= 0.7
		for i in range(GameManager.player_upgrades['half-draw']-1):
			charge_time *= 0.5
			beam_damage *= 0.7
			
			
		
		
	else:
		charge_timer -= 0.75
		
	max_attack_cooldown = charge_time + (0.1 if full_auto else 0.5)

		
func misc_update(delta):
	ai_move_timer -= delta
	
	if charging:
		charge_timer -= delta
		if charge_timer < 0:
			release_attack()
	
func player_action():
	if (Input.is_action_just_pressed("attack1") or (full_auto and Input.is_action_pressed("attack1"))) and attack_cooldown < 0:
		charge_attack()
	elif Input.is_action_just_pressed("attack2") and charging:
		special()
		
	if full_auto and Input.is_action_just_released('attack1') and charging:
		charging = false
		_on_AnimationPlayer_animation_finished('Attack')
		
	update_raycast()
	update_sight()
	
	if is_in_group("player"):
		GameManager.camera.offset = lerp(GameManager.camera.offset, (get_global_mouse_position() - global_position)/2, 0.1)
	
func ai_action():
	var to_target_point = ai_target_point - global_position
	
	var to_player = GameManager.player.global_position - global_position
	var player_dist = to_player.length()
	
	if not lock_aim:
		aim_direction = to_player/player_dist
		update_raycast()
		update_sight()
	
	if(to_target_point.length() > 5) and ai_move_timer > 0:
		target_velocity = to_target_point
		
	else:
		ai_target_point = global_position
		
		if attack_cooldown < 0 and (raycast_endpoint - global_position).length() > player_dist:
			ai_move_timer = 4
			if player_dist < 400:
				ai_target_point = global_position - aim_direction.rotated((randf()-0.5)*PI)*(20 + 50*randf())
				
			charge_attack()
	
	
func charge_attack():
	attacking = true
	charging = true
	attack_cooldown = max_attack_cooldown
	lock_aim = not full_auto
	max_speed = speed_while_charging
	
	charge_timer = charge_time
	animplayer.play("Ready")
	sight_beam.play("Flash")
	sight_beam.modulate = Color(1, 0, 0, 0.5)
	
func release_attack():
	charging = false
	animplayer.play("Attack")
	
	sight_beam.stop()
	sight_beam.frame = 1
	
	attack_fx.flip_h = aim_direction.x < 0
	attack_fx.offset.x = -10 if attack_fx.flip_h else 7
	attack_fx.frame = 0
	attack_fx.play("Flash")
	
	var beam_length = (raycast_endpoint - global_position).length()
	var beam_dir = (raycast_endpoint - global_position)/beam_length
	
	attack_beam.get_parent().rotation = beam_dir.angle()
	attack_beam.scale = Vector2(beam_length/32, beam_width)

	var attack_anim = attack_beam.get_node("AnimatedSprite")
	attack_anim.frame = 0
	attack_anim.play("Shoot")
	
	if is_in_group("player"):
		GameManager.camera.set_trauma(0.7*beam_damage/150, 4 if beam_damage > 100 else 5)
		
	LaserBeam.shoot_laser(global_position + Vector2(9*sign(aim_direction.x), 0), aim_direction, beam_width*6, self, beam_damage, 500, 0, true, 50, 'archer')
	
	melee_attack(attack_beam.get_node("CollisionShape2D"), beam_damage, 500, 0)
	
	var dist = 50
	var delay = 0.05
	while dist < beam_length:
		var point = global_position + beam_dir*dist
		GameManager.spawn_explosion(point, self, explosion_size, 40*explosion_size, 600*explosion_size, delay)
		dist += 50
		delay += 0.05
		
func special():
	charging = false
	sight_beam.stop()
	sight_beam.frame = 1
	animplayer.play("Special")
	
func area_attack():
	invincible = true
	melee_attack(deflector_shape, 20, 300, 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func update_raycast():
	raycast.cast_to = aim_direction*5000
	raycast_endpoint = raycast.get_collision_point() if raycast.is_colliding() else (global_position + aim_direction.normalized()*1000)

func update_sight():
	var beam_length = (raycast_endpoint - global_position).length()
	var beam_dir = (raycast_endpoint - global_position)/beam_length
	
	sight_beam.rotation = beam_dir.angle()
	sight_beam.scale.x = beam_length/80

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Ready":
		animplayer.play("Charge")
		
	elif anim_name == "Attack" or anim_name == "Special":
		attacking = false
		lock_aim = false
		invincible = false
		max_speed = walk_speed
		
		sight_beam.stop()
		sight_beam.frame = 0
		sight_beam.modulate = Color(1, 1, 1, 0.5)
		
	elif anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()


func _on_Timer_timeout():
	invincible = false
