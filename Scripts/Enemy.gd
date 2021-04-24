extends KinematicBody2D

onready var animplayer = $AnimationPlayer
onready var sprite = $Sprite
onready var swap_cursor = $BloodMoon

var health
var max_speed = 100
var velocity = Vector2.ZERO
var accel = 1
var facing_left = false
var attacking = false
var about_to_swap = false

var offset

func _physics_process(delta):
	if not is_in_group("enemy"):
		player_move()
		
		if about_to_swap:
			choose_swap_target()
		else:
			if Input.is_action_just_pressed("swap"):
				toggle_swap(true)
				
			player_action()
		
	else:
		ai_move()
		ai_action()
		
	animate()
	
func player_move():
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
		velocity = lerp(velocity, max_speed * input.normalized(), accel)
	else:
		velocity = lerp(velocity, Vector2.ZERO, accel)
		
	velocity = move_and_slide(velocity)
		
		
func player_action():
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
		
func ai_move():
	pass
		
func animate():
	if not attacking:
		if velocity.x > 0.5:
			facing_left = false
			sprite.flip_h = false
			sprite.position.x = -offset
		elif velocity.x < -0.5:
			facing_left = true
			sprite.flip_h = true
			sprite.position.x = offset

	if abs(velocity.x) <= 20 and !attacking:
		animplayer.play("Idle")
	elif !attacking:
		animplayer.play("Walk")
		
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
		get_node("/root/Node2D/Camera2D").anchor = self
	else:
		add_to_group("enemy")
		
	#is_player = state
	#Whatever else has to happewn
		
func die():
	queue_free()
		
	



