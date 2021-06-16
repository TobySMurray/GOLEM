extends "res://Scripts/Enemy.gd"

onready var dash_fx = $DashFX
onready var audio = $AudioStreamPlayer2D
onready var dash_audio = $Dash
onready var movement_raycast = $RayCast2D

var walk_speed
var burst_size
var shot_speed
var reload_time

var walk_speed_levels = [250, 250, 275, 300, 333, 366, 400, 450]
var burst_size_levels = [3, 4, 5, 6, 8, 10, 12]
var shot_speed_levels = [200, 300, 400, 500, 550, 600, 666]

var burst_count = 0
var burst_timer = 0

var dash_start_point = Vector2.ZERO
var dashing = false

var ai_target_point = Vector2.ZERO
var ai_retarget_timer = 0
var can_shoot = false

var path = []

# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = "wheel"
	health = 50
	max_speed = walk_speed
	accel = 2.5
	bullet_spawn_offset = 10
	flip_offset = -71
	healthbar.max_value = health
	max_attack_cooldown = 1
	max_special_cooldown = 0.8
	score = 60
	init_healthbar()
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	shot_speed = shot_speed_levels[level]
	burst_size = burst_size_levels[level]
	reload_time = 1 if state else 1.6
	
	movement_raycast.enabled = !state

func misc_update(delta):
	ai_retarget_timer -= delta
	
	if burst_count > 0:
		burst_timer -= delta
		if burst_timer < 0:
			shoot()
	else:
		lock_aim = false
		
	special_cooldown -= delta
	if special_cooldown < 0 and dashing:
		dashing = false
		lock_aim = false
		
	set_dash_fx_position()
	
func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0 and not attacking:
		start_burst()
	
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0 and not dashing:
		special_cooldown = 0.8
		dash()
		
func ai_move():
	var player_dist = (GameManager.player.global_position - global_position).length()
	can_shoot = player_dist < 300
	
	if player_dist < 400:
		if (ai_target_point - global_position).length_squared() < 225 or movement_raycast.is_colliding() or ai_retarget_timer < 0:
			ai_retarget_timer = 3
			var from_player = global_position - GameManager.player.global_position 
			var retarget_angle
			if randf() < 0.25:
				retarget_angle = from_player.angle() - PI + (randf()-0.5)*PI
			else:
				retarget_angle = from_player.angle() + randf()*PI/2*sign(from_player.cross(velocity))
				
			ai_target_point = GameManager.player.global_position + 150*Vector2(cos(retarget_angle), sin(retarget_angle))
			
			#var col = get_world_2d().direct_space_state.intersect_ray(global_position + foot_offset, ai_target_point + foot_offset, [self], collision_mask)
			#if col and (col['position'] - global_position).length_squared() < 400:
			#	ai_retarget_timer = -1
				
		target_velocity = ai_target_point - global_position
		movement_raycast.cast_to = target_velocity.normalized()*20
				
	else:
		target_velocity = Vector2.ZERO
		#target_velocity = astar.get_astar_target_velocity(global_position + foot_offset, GameManager.player.global_position)


func ai_action():
	if not lock_aim:
		aim_direction = (GameManager.player.global_position - global_position).normalized()
		
	if attack_cooldown < 0 and can_shoot:
		start_burst()
	
func start_burst():
	#lock_aim = is_in_group("enemy")
	attack_cooldown = reload_time
	burst_count = burst_size
	shoot()
	
func shoot():
	attacking = true
	audio.play()
	animplayer.play("Attack")
	animplayer.seek(0)
	
	if is_in_group("player"):
		GameManager.camera.set_trauma(0.3)
	
	velocity -= aim_direction*30
	shoot_bullet(aim_direction*shot_speed + velocity/2, 10)
	
	burst_timer = 0.45/burst_size
	burst_count -= 1
	
func dash():
	var dash_end_point = global_position + Vector2(83*sign(aim_direction.x), 0)
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position + foot_offset, dash_end_point + foot_offset, [self], collision_mask)
	if result:
		dash_end_point = result['position'] - foot_offset - (dash_end_point - global_position).normalized()*10 
	
	attacking = false
	burst_count = 0
	dashing = true
	lock_aim = true
	velocity = Vector2(sign(aim_direction.x)*150, 0)
	
	dash_start_point = global_position + Vector2((-70 if aim_direction.x < 0 else 0), 0)
	global_position = dash_end_point
	set_dash_fx_position()
	
	dash_audio.play()
	dash_fx.frame = 0
	dash_fx.flip_h = aim_direction.x < 0
	dash_fx.play("Swoosh")
	
	aim_direction.x *= -1
	
	
func set_dash_fx_position():
	dash_fx.global_position = dash_start_point

func take_damage(damage, source):
	if is_in_group('enemy') and special_cooldown < 0 and damage < health and randf() < 0.5:
		special_cooldown = 6
		aim_direction = velocity
		dash()
	.take_damage(damage, source)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Attack":
		attacking = false
	if anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()
