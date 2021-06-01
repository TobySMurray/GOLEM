extends "res://Scripts/Enemy.gd"

var num_pellets = 5

var walk_speed
var shot_spread
var shot_speed 
var fire_volume


var walk_speed_levels = [100, 115, 130, 145, 160, 175, 190]
var shot_speed_levels = [150, 175, 200, 225, 250, 280, 310]
var shot_spread_levels = [15, 15, 20, 25, 30, 40, 50]
var fire_volume_levels = [1, 1.2, 1.4, 1.8, 2.1, 2.4, 2.8]

var fuel = 200
var shot_timer = 0
var flamethrowing = false
var ai_shoot = false
var ai_target_point = Vector2.ZERO
var ai_retarget_timer = 0

onready var flamethrower = $Flamethrower


# Called when the node enters the scene tree for the first time.
func _ready():
	health = 110
	max_speed = walk_speed
	bullet_spawn_offset = 10
	flip_offset = -46
	max_attack_cooldown = 1
	score = 50
	init_healthbar()
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	shot_speed = shot_speed_levels[level]
	shot_spread = shot_spread_levels[level]
	fire_volume = fire_volume_levels[level]

func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0:
		attacking = true
		max_speed = 40
		attack()
	if Input.is_action_just_released("attack1"):
		flamethrowing = false
		animplayer.play("Cooldown")
		

func misc_update(delta):
	ai_retarget_timer -= delta
	
	if flamethrowing and fuel > 0:
		fuel -= 1
		
		shot_timer -= delta
		if shot_timer < 0:
			flamethrower()
			
	elif not attacking and fuel < 200:
		fuel += 5
		
	if fuel <= 0:
		flamethrowing = false
		animplayer.play("Cooldown")
		flamethrower.stop()
		attack_cooldown = 1

func attack():
	attacking = true
	max_speed = 40
	shot_timer = -1
	animplayer.play("Charge")
	flamethrower.play()
	
func flamethrower():
	flamethrower.play(0.5)
	
	var limited_aim_direction = limit_aim_direction(aim_direction)
	var pellets = max(fire_volume*fuel/50, 1)
	shot_timer = 40.0/(fuel+200)
	
	for i in range(pellets):
		var pellet_dir = limited_aim_direction.rotated((randf()-0.5)*deg2rad(shot_spread))
		var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
		shoot_bullet(pellet_dir*pellet_speed, 5, 0, 0.6)

func ai_move():
	if not lock_aim:
		aim_direction = (GameManager.player.global_position - global_position).normalized()
		
	var target_position = get_target_position()
	var target_dist = (target_position - global_position).length()
	
	if target_dist > 300:
		if ai_retarget_timer < 0:
			ai_retarget_timer = 1
			var path = astar.find_path(global_position + foot_offset, target_position)

			if len(path) == 0:
				target_position = global_position
				
			else:
				if GameManager.ground.world_to_map(path[0]) == GameManager.ground.world_to_map(global_position):
					if len(path) == 1:
						target_position = path[0]
					else:
						target_position = path[1]
				else:
					target_position = path[0]
					
			target_velocity = target_position - global_position
	
	else:
		target_velocity = target_position - global_position
		
	if target_dist < 100:
		if attack_cooldown < 0 and !ai_shoot:
			ai_shoot = true
			attack()
		elif attack_cooldown > 0 and ai_shoot:
			attack_cooldown = 1
			ai_shoot = false
	else:
		ai_shoot = false
		flamethrowing = false
		animplayer.play("Cooldown")
			
func get_target_position():
	var enemy_position = GameManager.player.shape.global_position
	var target_position
	
	if health < 25:
		target_position = enemy_position
	else:
		var enemy_tile_position = GameManager.ground.world_to_map(enemy_position)
		var target_tile_position
		if aim_direction.x > 0:
			target_tile_position = enemy_tile_position - Vector2(2, 0)
		else:
			target_tile_position = enemy_tile_position + Vector2(3, 0)
			
		target_position = GameManager.ground.map_to_world(target_tile_position)
		target_position.y = enemy_position.y
		
	return target_position
	
func limit_aim_direction(dir):
	var angle = dir.angle()
	if abs(angle) > PI/6 and abs(angle) < 5*PI/6:
		if abs(angle) < PI/2:
			angle = PI/6*sign(angle)
		else:
			angle = 5*PI/6*sign(angle)
			
	return Vector2(cos(angle), sin(angle))

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Charge":
		animplayer.play("Attack")
		flamethrowing = true
	if anim_name == "Cooldown":
		attacking = false
		lock_aim = false
		max_speed = walk_speed
	if anim_name == "Die":
		dead = true
		actually_die()


func _on_Timer_timeout():
	invincible = false
