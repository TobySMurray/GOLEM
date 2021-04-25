extends KinematicBody2D

class_name Enemy

onready var animplayer = $AnimationPlayer
onready var sprite = $Sprite
onready var swap_cursor = $BloodMoon
onready var bullet = load("res://Scenes/Bullet.tscn")
onready var transcender_curve = Curve2D.new()
onready var transcender = self.get_parent().get_node("Transcender")
onready var healthbar = $HealthBar

var health = 100
var max_speed = 100
var velocity = Vector2.ZERO
var target_velocity = Vector2.ZERO
var accel = 10
var facing_left = false
var attacking = false
var about_to_swap = false

var attack_cooldown = 0
var special_cooldown = 0

var aim_direction = Vector2.ZERO
var lock_aim = false

var flip_offset = 0
var bullet_spawn_offset = 0

var invincible = false

signal draw_transcender
signal clear_transcender

func _ready():
	self.connect("draw_transcender", transcender, "draw_transcender")
	self.connect("clear_transcender", transcender, "clear_transcender")

func _physics_process(delta):
	if health <= 0:
		return
	
	if not is_in_group("enemy"):
		if not lock_aim:
			aim_direction = (get_global_mouse_position() - global_position).normalized()
		
		player_move(delta)
		
		if about_to_swap:
			choose_swap_target()
		else:
			if Input.is_action_just_pressed("swap") and GameManager.swappable:
				toggle_swap(true)
				
			player_action()
		
	else:
		if GameManager.player:
			#aim_direction = Vector2.RIGHT #Will aim at player when defined
			ai_move()
			ai_action()
		
	attack_cooldown -= delta
	special_cooldown -= delta
	
	animate()
	move(delta)
	
	
func move(delta):
	velocity = lerp(velocity, target_velocity.normalized()*max_speed, accel*delta)	
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
		
	target_velocity = max_speed * input.normalized()
		
		
func player_action():
	pass
	
func ai_move():
	target_velocity = Vector2.ZERO
	
func ai_action():
	pass
		
func choose_swap_target():
	swap_cursor.global_position = get_global_mouse_position()
	if Input.is_action_just_released("swap"):
		if swap_cursor.selected_enemy:
			swap_cursor.selected_enemy.toggle_playerhood(true)
			toggle_playerhood(false)
			GameManager.swap_bar.control_timer = 0
			clear_transcender()
		toggle_swap(false)
	else:
		draw_transcender()
			
		
func animate():
	if aim_direction.x > 0:
		facing_left = false
		sprite.flip_h = false
		sprite.offset.x = 0
	else:
		facing_left = true
		sprite.flip_h = true
		sprite.offset.x = flip_offset

	if abs(velocity.x) < 20 and abs(velocity.y) < 20 and !attacking:
		animplayer.play("Idle")
	elif !attacking:
		animplayer.play("Walk")
		
		
func shoot_bullet(vel, damage = 10, mass = 0.25, lifetime = 10):
	var new_bullet = bullet.instance().duplicate()
	new_bullet.global_position = global_position + aim_direction*bullet_spawn_offset
	new_bullet.source = self
	new_bullet.velocity = vel
	new_bullet.damage = damage
	new_bullet.mass = mass
	new_bullet.lifetime = lifetime
	get_node("/root").add_child(new_bullet)
	
func melee_attack(collider, damage = 10, force = 50, deflect_power = 0):
	var space_rid = get_world_2d().space
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	
	var query = Physics2DShapeQueryParameters.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_layer =  6 if deflect_power > 0 else 4
	query.exclude = []
	query.transform = collider.global_transform
	query.set_shape(collider.shape)
	
	var results = space_state.intersect_shape(query, 32)
	for col in results:
		if col['collider'].is_in_group("hitbox"):
			var enemy = col['collider'].get_parent()
			if not enemy.invincible and not enemy == self:
				enemy.take_damage(damage)
				enemy.velocity += (enemy.global_position - global_position).normalized() * force
			
		elif col['collider'].is_in_group("bullet") and deflect_power > 0:
			var bullet = col['collider']
			var target = bullet.source
			if target and target != self:
				bullet.source = self
				bullet.lifetime += 2
				if deflect_power > 1:
					bullet.velocity = (target.global_position - bullet.global_position).normalized() * bullet.velocity.length()*2
				else:
					bullet.velocity = -bullet.velocity
		
func take_damage(damage):
	health -= damage
	healthbar.value = health
	if health <= 0:
		die()
	else:
		pass
		#animplayer.play("Hit")
func init_healthbar():
	healthbar.rect_scale.x = health / 200.0

func toggle_swap(state):
	about_to_swap = state
	
	if(about_to_swap):
		GameManager.lerp_to_timescale(0.1)
		swap_cursor.visible = true
		choose_swap_target()
	else:
		GameManager.lerp_to_timescale(1)
		swap_cursor.visible = false
		swap_cursor.selected_enemy = null
		swap_cursor.emit_selected_enemy_signal(false)
		clear_transcender()
		
func toggle_playerhood(state):
	if state == true:
		remove_from_group("enemy")
		add_to_group("player")
		get_node("../../../Camera2D").anchor = self
		GameManager.player = self
	else:
		remove_from_group("player")
		add_to_group("enemy")
		
	#is_player = state
	#Whatever else has to happen

func draw_transcender():
	
	transcender_curve = Curve2D.new()
	
	var enemy_position = get_global_mouse_position()
	var my_position = self.position
	var mid_point = (enemy_position + my_position)/2
	var mid_point_adjusted = mid_point + Vector2(0, 1)
	var influx_point_1 = Vector2((mid_point.x + my_position.x) / 2 , mid_point.y - 200).abs()
	var influx_point_2 = Vector2(enemy_position.x + ((mid_point.x + my_position.x) / 2), mid_point.y - 100).abs()

	var p0_vertex = my_position # First point of first line segment
	var p0_out = (Vector2(my_position.x, my_position.y - 75) - my_position) # Second point of first line segment
	var p1_in = (Vector2(enemy_position.x, enemy_position.y - 75) - enemy_position) # First point of second line segment
	var p1_vertex = enemy_position # Second point of second line segment
	
	var p0_in = Vector2.ZERO # This isn't used for the first curve
	var p1_out = Vector2.ZERO # Not used unless another curve is added

	transcender_curve.add_point(p0_vertex, p0_in, p0_out);
	transcender_curve.add_point(p1_vertex, p1_in, p1_out);
	
	emit_signal("draw_transcender", transcender_curve)
	
	
func animate_transcender():
	# animate the transcendor
	
	# and then clear it
	clear_transcender()
	
func clear_transcender(): 
		emit_signal("clear_transcender")
		
func toggle_selected_enemy(enemy_is_selected):
	if enemy_is_selected:
		emit_signal("toggle_selected_enemy")

func die():
	attacking = true
	animplayer.play("Die")
		
	



