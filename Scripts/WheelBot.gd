extends "res://Scripts/Enemy.gd"

onready var dash_fx = $DashFX
onready var audio = $AudioStreamPlayer2D
onready var dash = $Dash

var walk_speed
var burst_size
var shot_speed

var walk_speed_levels = [250, 250, 275, 300, 325, 350]
var burst_size_levels = [3, 4, 5, 6, 8]
var shot_speed_levels = [200, 300, 400, 500, 550]

var burst_count = 0
var burst_timer = 0

var dash_start_point = Vector2.ZERO
var dashing = false
var dash_timer = 0

var ai_target_point = Vector2.ZERO
var ai_retarget_timer = 0

var path = []

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 50
	max_speed = walk_speed
	accel = 2.5
	bullet_spawn_offset = 10
	flip_offset = -71
	healthbar.max_value = health
	score = 25
	init_healthbar()
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else 0
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	shot_speed = shot_speed_levels[level]
	burst_size = burst_size_levels[level]
		

func misc_update(delta):
	ai_retarget_timer -= delta
	
	if burst_count > 0:
		burst_timer -= delta
		if burst_timer < 0:
			shoot()
	else:
		lock_aim = false
		
	dash_timer -= delta
	if dash_timer < 0 and dashing:
		dashing = false
		lock_aim = false
		
	set_dash_fx_position()
	
func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0 and not attacking:
		start_burst()
	
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0 and not attacking and not dashing:
		dash()
		
func ai_move():
	if (GameManager.player.global_position - global_position).length() > 400:
		if (ai_target_point - global_position).length_squared() < 10 or ai_retarget_timer < 0:
			
			ai_retarget_timer = 3
			var from_player = global_position - GameManager.player.global_position 
			var retarget_angle
			if randf() < 0.25:
				retarget_angle = from_player.angle() - PI + (randf()-0.5)*PI
			else:
				retarget_angle = from_player.angle() + (randf()-0.5)*PI/2


			ai_target_point = 150*Vector2(cos(retarget_angle), sin(retarget_angle))
			target_velocity = ai_target_point - global_position
	elif ai_retarget_timer < 0:
		ai_retarget_timer = 1
		target_velocity = astar.get_astar_target_velocity(global_position + foot_offset, GameManager.player.global_position)

		
	
	
func ai_action():
	aim_direction = (GameManager.player.global_position - global_position).normalized()
	if attack_cooldown < 0:
		start_burst()
	
func start_burst():
	lock_aim = is_in_group("enemy")
	attack_cooldown = 1
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
	dashing = true
	lock_aim = true
	dash.play()
	velocity = Vector2(sign(aim_direction.x)*150, 0)
	
	dash_timer = 0.8
	dash_start_point = global_position + Vector2((-70 if aim_direction.x < 0 else 0), 0)
	global_position += Vector2(83*sign(aim_direction.x), 0)
	
	dash_fx.frame = 0
	dash_fx.flip_h = aim_direction.x < 0
	dash_fx.play("Swoosh")
	
	aim_direction.x *= -1
	
	
func set_dash_fx_position():
	dash_fx.global_position = dash_start_point


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Attack":
		attacking = false
	if anim_name == "Die":
		dead = true
		actually_die()


func _on_Timer_timeout():
	invincible = false
