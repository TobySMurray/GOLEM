extends KinematicBody2D

class_name Enemy

onready var animplayer = $AnimationPlayer
onready var sprite = $Sprite
onready var swap_cursor = $BloodMoon
onready var bullet = load("res://Scenes/Bullet.tscn")

var health
var max_speed = 100
var velocity = Vector2.ZERO
var accel = 10
var facing_left = false
var attacking = false
var about_to_swap = false

var attack_cooldown = 0
var special_cooldown = 0

var aim_direction
var lock_aim = false

var flip_offset = 0
var bullet_spawn_offset = 0

func _physics_process(delta):
	if not is_in_group("enemy"):
		if not lock_aim:
			aim_direction = (get_global_mouse_position() - global_position).normalized()
		
		player_move(delta)
		
		if about_to_swap:
			choose_swap_target()
		else:
			if Input.is_action_just_pressed("swap"):
				toggle_swap(true)
				
			player_action()
		
	else:
		aim_direction = Vector2.RIGHT #Will aim at player when defined
		ai_move()
		ai_action()
		
	attack_cooldown -= delta
	special_cooldown -= delta	
	
	animate()
	velocity = move_and_slide(velocity)
	
func player_move(delta):
	var input = Vector2()
	if Input.is_action_pressed("move_right"):
		input.x += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_down"):
		input.y += 1
	if Input.is_action_pressed("move_up"):
		input.y -= 1
	
	if abs(input.x) > 0 or abs(input.y) > 0:
		velocity = lerp(velocity, max_speed * input.normalized(), accel*delta)
	else:
		velocity = lerp(velocity, Vector2.ZERO, accel*delta)
		
		
func player_action():
	pass
	
func ai_move():
	pass
	
func ai_action():
	pass
		
func choose_swap_target():
	swap_cursor.global_position = get_global_mouse_position()
	if Input.is_action_just_released("swap"):
		if swap_cursor.selected_enemy:
			swap_cursor.selected_enemy.toggle_playerhood(true)
			toggle_playerhood(false)
			
		
		toggle_swap(false)
		

		
func animate():
	if not attacking:
		if aim_direction.x > 0:
			facing_left = false
			sprite.flip_h = false
			sprite.offset.x = 0
		else:
			facing_left = true
			sprite.flip_h = true
			sprite.offset.x = flip_offset

	if abs(velocity.x) <= 20 and abs(velocity.y) <= 20 and !attacking:
		animplayer.play("Idle")
	elif !attacking:
		animplayer.play("Walk")
		
		
func shoot_bullet(vel, damage):
	var new_bullet = bullet.instance().duplicate()
	new_bullet.global_position = global_position + aim_direction*bullet_spawn_offset
	new_bullet.source = self
	new_bullet.velocity = vel
	new_bullet.damage = damage
	get_node("/root").add_child(new_bullet)
		
func take_damage(damage):
	health -= damage
	if health <= 0:
		die()
	else:
		animplayer.play("Hit")
		
func toggle_swap(state):
	about_to_swap = state
	
	if(about_to_swap):
		GameManager.lerp_to_timescale(0.25)
		swap_cursor.visible = true
		choose_swap_target()
	else:
		GameManager.lerp_to_timescale(1)
		swap_cursor.visible = false
		swap_cursor.selected_enemy = null
		
func toggle_playerhood(state):
	if state == true:
		remove_from_group("enemy")
		get_node("../Camera2D").anchor = self
	else:
		add_to_group("enemy")
		
	#is_player = state
	#Whatever else has to happewn
		
func die():
	queue_free()
		
	



