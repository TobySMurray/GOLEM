extends "res://Scripts/Enemy.gd"

onready var grapple = $Grapple
onready var attack_collider = $AttackCollider/NeutralCollider
onready var forward_collider = $AttackCollider/ForwardCollider
onready var side_collider = $AttackCollider/SideCollider
onready var back_collider = $AttackCollider/BackCollider
onready var audio = $AudioStreamPlayer2D


var num_pellets = 5
var walk_speed
var shot_speed
var charge_speed
var init_charge

var shot_speed_levels = [150, 175, 200, 225, 250, 275, 300]
var walk_speed_levels = [130, 160, 190, 220, 250, 270, 280]
var charge_speed_levels = [1.0, 1.2, 1.4, 1.6, 2.0, 2.1, 2.2]
var init_charge_levels = [0.3, 0.2, 0.2, 0.25, 0.3, 0.4, 0.5]
var quickstep_cooldown_levels = [5, 0.1, 3.5, 3, 2.66, 2.33, 2]
var grapple_force_levels = [15, 18, 20, 22, 24, 26, 28]

var kb_mult = 1
var damage_mult = 1
var grapple_stun = 0
var laminar_shockwave = false
var speed_while_charging = 20
var footwork = false
var grapple_launch_speed = 400
var steady_body = false

var charging = false
var charge_level = 0

var can_combo = false
var combo_buffered = false

var quickstepping = false
var quickstep_timer = 0
var charge_started_during_quickstep = false

var ai_state = 'approach'
var ai_side = 1
var ai_target_dist= 0
var ai_target_angle = 0
var ai_move_timer = 0
var ai_delay_timer = 0
var ai_charge_timer = 0
onready var ai_target_point = global_position

var double_tap_timer = 0
var grapple_stun_timer = 0
var tug_timer = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.CHAIN
	max_health = 100
	bullet_spawn_offset = 20
	flip_offset = 3
	score = 50
	init_healthbar()
	max_attack_cooldown = 0.6
	toggle_enhancement(false)
	
func toggle_playerhood(state):
	.toggle_playerhood(state)
	if charging:
		if is_instance_valid(grapple.anchor_entity):
			aim_direction = (grapple.anchor_entity.global_position - global_position).normalized()
		attack()
	
func toggle_enhancement(state):
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	shot_speed = shot_speed_levels[level]
	charge_speed = charge_speed_levels[level]
	init_charge = init_charge_levels[level]
	max_special_cooldown = quickstep_cooldown_levels[level]
	grapple.retract_force = grapple_force_levels[level]
	
	kb_mult = 1
	damage_mult = 1
	speed_while_charging = 20
	grapple_stun = 0
	grapple_launch_speed = 400
	laminar_shockwave = false
	footwork = false
	steady_body = false
	
	if state == true:
		init_charge += charge_speed*0.15*GameManager.player_upgrades['precompressed_hydraulics']
		for i in range(GameManager.player_upgrades['precompressed_hydraulics']):
			charge_speed *= 0.8
		
		kb_mult -= min(0.95, 0.5*GameManager.player_upgrades['adaptive_wrists'])
		damage_mult += 0.2*GameManager.player_upgrades['adaptive_wrists']
		
		grapple_stun = GameManager.player_upgrades['frayed_wires']
		
		footwork = GameManager.player_upgrades['footwork_scheduler'] > 0
		speed_while_charging = max(20, GameManager.player_upgrades['footwork_scheduler']*walk_speed*0.4)
		
		laminar_shockwave = GameManager.player_upgrades['vortex_technique'] > 0
		
		grapple_launch_speed *= 1 + GameManager.player_upgrades['reverse_polarity']*0.5
		
		steady_body = GameManager.player_upgrades['perfect_balance'] > 0
		
	.toggle_enhancement(state)
		
		
func misc_update(delta):
	ai_charge_timer -= delta
	ai_move_timer -= delta
	ai_delay_timer -= delta
	double_tap_timer -= delta
	tug_timer -= delta
	quickstep_timer -= delta
	
	if charging:
		charge_level += delta*charge_speed
		
	if quickstepping and quickstep_timer < 0.5:
		if charging and not charge_started_during_quickstep:
			attack()
		if quickstep_timer < 0.3:
			quickstepping = false
			if charging:
				charge_started_during_quickstep = false
			if not attacking:
				override_speed = null
		
	if grapple_stun > 0 and is_instance_valid(grapple.anchor_entity):
		grapple_stun_timer -= delta
		if grapple_stun_timer < 0:
			grapple_stun_timer = 2.0/grapple_stun
			grapple.anchor_entity.take_damage(0, self, 0.75)
			
			
#	attack_collider.position.x = -34 if facing_left else 34
#	if facing_left:
#		$Shadow.offset.x = -8
#	if !facing_left:
#		$Shadow.offset.x = 0

func player_action():
	if is_instance_valid(grapple.anchor_entity):
		aim_direction = (grapple.anchor_entity.global_position - global_position).normalized()
		
	if Input.is_action_pressed("attack1") and not can_combo and attack_cooldown < 0 and not attacking:
		charge()
			
	if Input.is_action_just_released('attack1') and can_combo:
		combo_buffered = true
		
	elif not Input.is_action_pressed("attack1") and charging:
		attack()
			
	if grapple.state == grapple.ANCHORED:
		if Input.is_action_pressed('attack2'):
			grapple.tugged = true
			tug_timer = 0.1
		else:
			grapple.tugged = false
			
		if Input.is_action_just_pressed('attack2'):
			if double_tap_timer > 0:
				grapple.retract(false)
			else:
				double_tap_timer = 0.2
				
	elif Input.is_action_just_pressed('attack2'):
		if grapple.state == grapple.LAUNCHED:
			grapple.retract(false)
		else:
			launch_grapple(aim_direction)
			
	if Input.is_action_just_pressed('utility') and quickstep_timer < 0 and (not charging or footwork):
		quickstep(target_velocity)
		
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
	
		if not immobile:
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
						
		else:
			if ai_delay_timer < 0 and not charging and not attacking:
				to_player = player_pos + GameManager.player.velocity*0.5 - global_position
				if abs(to_player.x) < 200 and to_player.aspect() > 1:
					ai_charge_timer = 0.2 + randf()*0.5
					ai_delay_timer = ai_charge_timer + 0.3
					charge()

func charge():
	charging = true
	attacking = true
	lock_aim = not is_player
	override_speed = speed_while_charging
	charge_started_during_quickstep = quickstep_timer > 0.3 and not charge_started_during_quickstep
	charge_level = init_charge
	play_animation("Charge")
	
func attack(combo = false):
	charging = false
	combo_buffered = false
	can_combo = !combo
	attack_cooldown = max_attack_cooldown if combo else 0
	attack_collider.position.x = -34 if facing_left else 34
	play_animation('Attack2' if combo else 'Attack')
	
func launch_grapple(dir):
	grapple.launch(dir.normalized()*grapple_launch_speed)
	grapple_stun_timer = 0
	
func quickstep(dir):
	special_cooldown = max_special_cooldown
	dir = dir.normalized()
	velocity = 1000*dir
	quickstepping = true
	override_speed = 0
	quickstep_timer = 0.6
	
	
func quickstep_attack(dir):
	var stun = 0#melee_stun*charge_level/charge_speed - init_charge/2
	if dir == Vector2.ZERO:
		dir = Vector2(-sign(aim_direction.x), 0)
	else:
		dir = Vector2(sign(dir.x), 0) if abs(dir.x) > abs(dir.y) else Vector2(0, sign(dir.y))
		
	if dir.x == 1:
		Violence.melee_attack(self, forward_collider, 50*charge_level*damage_mult, 1200*charge_level*kb_mult, charge_level+1, stun)
	elif dir.x == -1:
		Violence.melee_attack(self, back_collider, 50*charge_level*damage_mult, 600*charge_level*kb_mult, charge_level+1, stun)
	else:
		side_collider.position.y = -26 if dir.y < 0 else 38
		Violence.melee_attack(self, side_collider, 40*charge_level*damage_mult, 600*charge_level*kb_mult, charge_level+1, stun)

func swing_attack():
	num_pellets = 1 + int(3*charge_level)
	var spread = 120*charge_level
	var dir = Vector2(1, 0)
	var angle = -spread/2
	var delta_angle = spread/(num_pellets)
	var stun = 0#melee_stun*charge_level/charge_speed - init_charge/2
	
	if is_player:
		GameManager.camera.set_trauma(min(0.3 + charge_level*0.2, 1))
	
	if facing_left:
		angle *= -1
		delta_angle *= -1
		dir.x *= -1
		
	if footwork:
		velocity += dir*300 

	if laminar_shockwave:
		var power = sqrt(6*charge_level)
		var size = min(0.5 + power, 8)
		var wave_dir = Util.limit_horizontal_angle(aim_direction, PI/8)
		#var speed_mult = sqrt(num_pellets)*0.6
		var bullet = Violence.shoot_vortex_wave(self, global_position + wave_dir*bullet_spawn_offset, wave_dir*shot_speed*(1 + power/8.0), 3*power, 1.0 + power/4.0, 1.5, stun*0.2, Vector2(size*0.7, size))
		
	else:
		for i in num_pellets + 1:
			var pellet_dir = dir.rotated(deg2rad(angle))
			angle += delta_angle
			var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
			shoot_bullet(pellet_dir*pellet_speed, 10, 0.5, 1, 'wave', stun*0.5)
			
	var damage = 50*charge_level*damage_mult
	var kb = 800*charge_level*kb_mult
	
	var grapple_boost = false
	var velocity_bonus = 0.0
	var kb_bonus = 0.0
	if is_instance_valid(grapple.anchor_entity) and tug_timer > 0:
		tug_timer = 0.0
		grapple_boost = true
		velocity_bonus = (velocity - grapple.anchor_entity.velocity).project(global_position - grapple.anchor_entity.global_position).length()
		#damage *= sqrt(1.0 + velocity_bonus/1000.0)
		kb  += velocity_bonus*2
		
	print("DAMAGE: " + str(damage))
	var hits = Violence.melee_attack(self, attack_collider, damage, kb + kb_bonus, charge_level+1, stun)
	
	var rebound = Vector2.ZERO
	var hit_mass = 0.0
	var num_hits = 0
	for entity in hits:
		if entity.is_in_group('enemylike'):
			rebound += (global_position - entity.global_position).normalized()*entity.mass
			hit_mass += entity.mass
			num_hits += 1
			
	if hit_mass > 0:
		velocity += (1 - mass/(hit_mass + mass))*kb*(rebound/hit_mass)*(0.5 if steady_body else 1.0)
	
	if grapple_boost and is_player and velocity_bonus > 200:
		for entity in hits:
			if entity == grapple.anchor_entity:
				GameManager.set_timescale(0.001, velocity_bonus/2500, 100)
				var kb_dir = entity.global_position.direction_to(get_global_mouse_position())
				if kb_dir.dot(entity.global_position - global_position) > 0: 
					entity.velocity = entity.velocity.length()*kb_dir
				break

	if charge_level > 2:
		GameManager.spawn_explosion(global_position + Vector2((-20 if facing_left else 20), 0), self, 1, 10)
	
func die(killer = null):
	grapple.retract()
	.die(killer)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Charge":
		attack()
		
	elif anim_name == "Attack" or anim_name == "Attack2":
		if anim_name == 'Attack' and combo_buffered:
			print("COMBO")
			attack(true)
		else:
			attacking = false
			lock_aim = false
			can_combo = false
			override_speed = null
			
	elif anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()
