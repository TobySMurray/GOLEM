extends "res://Scripts/Enemy.gd"

onready var dash_fx = $DashFX

var walk_speed = 250
var burst_count = 0
var burst_timer = 0

var dash_start_point = Vector2.ZERO
var dashing = false
var dash_timer = 0

var ai_target_point = Vector2.ZERO
var ai_retarget_timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 75
	max_speed = walk_speed
	accel = 2.5
	bullet_spawn_offset = 10
	flip_offset = -71
	init_healthbar()
	
func _process(delta):
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
	if (ai_target_point - global_position).length_squared() < 100 or ai_retarget_timer < 0:
		ai_retarget_timer = 3
		var from_player = global_position - GameManager.player.global_position 
		var retarget_angle
		if randf() < 0.25:
			retarget_angle = from_player.angle() - PI + (randf()-0.5)*PI
		else:
			retarget_angle = from_player.angle() + (randf()-0.5)*PI/2
			
		ai_target_point = 150*Vector2(cos(retarget_angle), sin(retarget_angle))
			
	target_velocity = ai_target_point - global_position
	
func ai_action():
	aim_direction = (GameManager.player.global_position - global_position).normalized()
	if attack_cooldown < 0:
		start_burst()
	
func start_burst():
	lock_aim = true
	attack_cooldown = 1
	burst_count = 3
	shoot()
	
func shoot():
	attacking = true
	animplayer.play("Attack")
	animplayer.seek(0)
	
	velocity -= aim_direction*30
	shoot_bullet(aim_direction*250 + velocity/2, 10)
	
	burst_timer = 0.15
	burst_count -= 1
	
func dash():
	dashing = true
	lock_aim = true
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
	elif anim_name == "Die":
		queue_free()
