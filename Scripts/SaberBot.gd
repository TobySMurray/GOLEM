extends "res://Scripts/Enemy.gd"

onready var SaberRing = load("res://Scenes/SaberRing.tscn")
onready var GhostImage = load("res://Scenes/GhostImage.tscn")
onready var slash_trigger = $SlashTrigger
onready var slash_collider = $SlashCollider
onready var LOS_raycast = $LineOfSightRaycast


var walk_speed
var dash_speed
var slash_charges
var saber_ring_durability

var walk_speed_levels = [90, 100, 110, 120, 130, 140, 150]
var dash_speed_levels = [250, 300, 333, 366, 400, 450, 500]
var slash_charges_levels = [1, 1, 2, 3, 4, 5, 5]
var max_special_cooldown_levels = [10, 6, 6, 6, 6, 6, 4]
var saber_ring_durability_levels = [0.1, 0.15, 0.175, 0.2, 0.225, 0.250, 0.275]

var saber_ring = null
var sabers_sheathed = true
var waiting_for_saber_recall = false

var in_kill_mode = false
var kill_mode_buffered = false
var kill_mode_timer = 0
var remaining_slashes = 0

var ai_move_timer = 0
var ai_target_point = Vector2.ZERO

var ghost_timer = 0
var rage_color = Color(1, 0, 0.45)

func _ready():
	health = 75
	max_speed = walk_speed
	flip_offset = -16
	healthbar.max_value = health
	max_attack_cooldown = 2
	score = 80
	init_healthbar()
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	dash_speed = dash_speed_levels[level]
	max_speed = walk_speed
	slash_charges = slash_charges_levels[level]
	max_special_cooldown = max_special_cooldown_levels[level]
	saber_ring_durability = saber_ring_durability_levels[level]
	
	LOS_raycast.enabled = !state
	
func misc_update(delta):
	.misc_update(delta)
	ai_move_timer -= delta
	
	if not sabers_sheathed and not waiting_for_saber_recall and saber_ring.accel <= 0:
		attack_cooldown = 2
		recall_sabers()
	
	if waiting_for_saber_recall and saber_ring.recalled:
		waiting_for_saber_recall = false
		start_sheath()
		
	if in_kill_mode or special_cooldown < 0:
		sprite.light_mask = 2
	else:
		sprite.light_mask = 5
		
	if in_kill_mode:
		special_cooldown = max_special_cooldown
		kill_mode_timer -= delta
		if kill_mode_timer < 0:
			end_kill_mode()
			
		ghost_timer -= delta
		if ghost_timer < 0:
			ghost_timer = 30.0/dash_speed
			spawn_ghost_image()
			
			
	elif special_cooldown < 0:
		base_color = Color.white.linear_interpolate(rage_color, sin(GameManager.game_time*5)/2 + 0.5) 
	
func player_action():
	.player_action()
	if not attacking and not in_kill_mode and attack_cooldown < 0 and Input.is_action_just_pressed("attack1"):
		if sabers_sheathed:
			start_unsheath()
		else:
			recall_sabers()
			
	if not attacking and special_cooldown < 0 and Input.is_action_just_pressed("attack2"):
		if sabers_sheathed:
			start_kill_mode()
		else:
			kill_mode_buffered = true
			recall_sabers()
			
	if not sabers_sheathed:
		if waiting_for_saber_recall:
			saber_ring.target_pos = global_position + Vector2(-29 if facing_left else 29, -8)
		else:
			var to_mouse = get_global_mouse_position() - global_position
			if to_mouse.length() < 100:
				saber_ring.target_pos = global_position + to_mouse
			else:
				saber_ring.target_pos = global_position + to_mouse.normalized()*100

				
func ai_move():
	var to_player = GameManager.player.global_position - global_position
	var player_dist = to_player.length()
	var player_on_screen = abs(to_player.x) < 200 and abs(to_player.y) < 140
	aim_direction = to_player
	LOS_raycast.cast_to = to_player
	
	#action
	if special_cooldown < 0:
		if player_on_screen and not LOS_raycast.is_colliding():
			if not sabers_sheathed and not waiting_for_saber_recall:
				kill_mode_buffered = true
				recall_sabers()
			elif not attacking and sabers_sheathed:
				start_kill_mode()
			
		if not sabers_sheathed and not waiting_for_saber_recall:	
			orbit_sabers()
			
	elif not in_kill_mode:
		if sabers_sheathed:
			if attack_cooldown < 0 and not attacking and not kill_mode_buffered:
				start_unsheath()
		else:
			if LOS_raycast.is_colliding():
				orbit_sabers()
			else:
				var angle_offset = sin(GameManager.game_time*3)*PI/9
				saber_ring.target_pos = global_position + to_player.normalized().rotated(angle_offset)*60
				
	#move
	if in_kill_mode:
		if GameManager.player.dead:
			target_velocity = Vector2.ZERO
		else:
			var side = -sign(to_player.x)
			var to_point = GameManager.player.global_position + Vector2(20*side, 0) - global_position
			target_velocity = to_point
	
	elif special_cooldown < 0:
		if not LOS_raycast.is_colliding() and not attacking:
			target_velocity = to_player
		else:
			target_velocity = Vector2.ZERO
			
	else:
		if ai_move_timer < 0:
			ai_move_timer = -1 if sabers_sheathed else randf() + 1
			if player_dist < 400:
				ai_target_point = global_position - to_player.rotated((randf()-0.5)*PI)*(20 + 30*randf())
			else:
				ai_target_point = global_position
				
func orbit_sabers():
	var angle = sin(GameManager.game_time)*PI*2
	saber_ring.target_pos = global_position + Vector2(cos(angle), sin(angle))*20
	

func start_kill_mode():
	in_kill_mode = true
	special_cooldown = max_special_cooldown
	max_speed = dash_speed
	slash_trigger.get_node("CollisionShape2D").set_deferred("disabled", false)
	remaining_slashes = slash_charges
	sprite.modulate = rage_color
	base_color = rage_color
	kill_mode_timer = 1
	
	if is_in_group("player"):
		GameManager.lerp_to_timescale(0.75)
	
func end_kill_mode():
	in_kill_mode = false
	max_speed = walk_speed
	slash_trigger.get_node("CollisionShape2D").set_deferred("disabled", true)
	sprite.modulate = Color.white
	base_color = Color.white
	
	if is_in_group("player"):
		GameManager.lerp_to_timescale(1)
	
func slash():
	attacking = true
	kill_mode_timer = 1
	animplayer.play("Special")
	slash_collider.position.x = -10 if facing_left else 10
	melee_attack(slash_collider, 150, 1000, 5)
	set_invincibility_time(0.25)
	
	if is_in_group("player"):
		GameManager.camera.set_trauma(0.6)
		GameManager.timescale = 0.0
		
func end_slash():
	attacking = false
	remaining_slashes -= 1
	if remaining_slashes <= 0:
		end_kill_mode()
			
func start_unsheath():
	lock_aim = true
	attacking = true
	animplayer.play("Unsheath")
	
func recall_sabers():
	lock_aim = true
	attacking = true
	saber_ring.recall()
	waiting_for_saber_recall = true
	
func start_sheath():
	sabers_sheathed = true
	saber_ring.queue_free()
	saber_ring = null
	animplayer.play("Sheath")
	
func on_sabers_sheathed():
	lock_aim = false
	attacking = false
	walk_anim = "Walk"
	idle_anim = "Idle"
	if kill_mode_buffered:
		kill_mode_buffered = false
		start_kill_mode()
	
func on_sabers_unsheathed():
	sabers_sheathed = false
	saber_ring = SaberRing.instance().duplicate()
	get_parent().add_child(saber_ring)
	saber_ring.source = self
	saber_ring.global_position = global_position + Vector2(-29 if facing_left else 29, -8)
	saber_ring.visible = true
	saber_ring.mass = saber_ring_durability
	lock_aim = false
	attacking = false
	walk_anim = "Walk Saberless"
	idle_anim = "Idle Saberless"

func _on_SlashTrigger_area_entered(area):
	if in_kill_mode and not attacking and not area.get_parent() == self and area.is_in_group("hitbox") and not area.get_parent().invincible:
		velocity = (area.global_position - global_position).normalized() * 1000
		slash()
		
func spawn_ghost_image():
	var new_ghost = GhostImage.instance().duplicate()
	get_parent().add_child(new_ghost)
	new_ghost.copy_sprite(sprite)
	new_ghost.set_lifetime(0.4)
	
func take_damage(damage, source):
	if in_kill_mode:
		damage /= 2
	.take_damage(damage, source)
		
func actually_die():
	if not sabers_sheathed:
		saber_ring.queue_free()
	.actually_die()
