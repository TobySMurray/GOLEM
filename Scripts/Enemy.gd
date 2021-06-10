extends KinematicBody2D

class_name Enemy

onready var animplayer = $AnimationPlayer
onready var sprite = $Sprite
onready var swap_cursor = $BloodMoon
onready var swap_shield = $ClearMoon
onready var bullet = load("res://Scenes/Bullet.tscn")
onready var score_popup = load("res://Scenes/ScorePopup.tscn")
onready var transcender_curve = Curve2D.new()
onready var transcender = self.get_parent().get_node("Transcender")
onready var healthbar = $HealthBar
onready var EV_particles = $EVParticles
onready var astar = self.get_parent().get_node("AStar")
onready var slow_audio = $BloodMoon/Slow
onready var stopped_audio = $BloodMoon/Stopped
onready var speed_audio = $BloodMoon/Speed
onready var timer = $Timer
onready var shape = $CollisionShape2D
onready var light_circle = $CharacterLights/Radial
onready var light_beam = $CharacterLights/Directed

onready var ScoreLabel = get_node("../../../Camera2D/CanvasLayer/DeathScreen/ScoreLabel")
onready var death_screen = get_node("../../../Camera2D/CanvasLayer/DeathScreen")
onready var ScoreDisplay = get_node("../../../Camera2D/CanvasLayer/ScoreDisplay")


var health = 100
var max_speed = 100
var mass = 1
var velocity = Vector2.ZERO
var target_velocity = Vector2.ZERO
var accel = 10
var light_color = Color.white
var base_color = Color.white

var facing_left = false
var attacking = false
var about_to_swap = false
var score = 0

var game_over = false

var is_boss = false
var enemy_evolution_level = 0

var max_swap_shield_health = 0
var swap_shield_health = 0

var attack_cooldown = 0
var max_attack_cooldown
var special_cooldown = 0
var max_special_cooldown = 0
var time_since_controlled = 1000

var aim_direction = Vector2.ZERO
var lock_aim = false

var flip_offset = 0
var bullet_spawn_offset = 0
var foot_offset = 0

var invincible = false
var invincibility_timer = 0

var capturing_boss = false
var boss_capture_timer = 0

signal draw_transcender
signal clear_transcender

var idle_anim = "Idle"
var walk_anim = "Walk"

var dead = false
var force_swap = false


func _ready():
	self.connect("draw_transcender", transcender, "draw_transcender")
	self.connect("clear_transcender", transcender, "clear_transcender")
	GameManager.audio = get_node("/root/Level/AudioStreamPlayer")
	foot_offset = Vector2(0, get_node("CollisionShape2D").position.y)
	update_swap_shield()

func _physics_process(delta):
	if not dead:
		misc_update(delta)
		
	if not is_in_group("enemy"):
		if capturing_boss:
			boss_capture_timer -= 0.016
			GameManager.camera.trauma = 0.3
			
			if boss_capture_timer < 0 or dead:
				capturing_boss = false
				on_boss_capture()
				
		if not capturing_boss:
			if not dead:
				player_move(delta)
				
				
				if not lock_aim:
					aim_direction = (get_global_mouse_position() - global_position).normalized()
					light_beam.rotation = aim_direction.angle() - PI/2
				
			if about_to_swap:
				choose_swap_target()
			else:
				if not dead:
					player_action()
					
				if GameManager.swappable:
					if Input.is_action_just_pressed("swap"):
						toggle_swap(true)
		
		
	else:
		time_since_controlled += delta
		if GameManager.player and not dead:
			ai_move()
			ai_action()
		
	attack_cooldown -= delta
	special_cooldown -= delta
	
	if invincible:
		invincibility_timer -= delta
		if invincibility_timer < 0:
			invincible = false
	
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
	
func misc_update(delta):
	pass
		
func player_action():
	pass
	
func ai_move():
	target_velocity = Vector2.ZERO
	
func ai_action():
	pass
		
func choose_swap_target():
	swap_cursor.global_position = get_global_mouse_position()
	
	var swapbar = GameManager.swap_bar
	GameManager.camera.lerp_zoom(1 + (swapbar.control_timer - swapbar.swap_threshold)/swapbar.max_control_time)
	
	if GameManager.swappable:
		if Input.is_action_just_released("swap"):
			if swap_cursor.selected_enemy:
				swap_cursor.selected_enemy.toggle_playerhood(true)
				toggle_playerhood(false)
				GameManager.swap_bar.reset()
				
			if swap_cursor.selected_enemy or !dead:
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
		animplayer.play(idle_anim)
	elif !attacking:
		animplayer.play(walk_anim)
		
	sprite.modulate = lerp(sprite.modulate, base_color, 0.2)
		
		
func shoot_bullet(vel, damage = 10, mass = 0.25, lifetime = 10):
	var new_bullet = bullet.instance().duplicate()
	new_bullet.global_position = global_position + aim_direction*bullet_spawn_offset
	new_bullet.source = self
	new_bullet.velocity = vel * 0.8
	new_bullet.damage = damage
	new_bullet.mass = mass
	new_bullet.lifetime = lifetime
	get_node("/root").add_child(new_bullet)
	
	if is_in_group("player"):
		GameManager.player_bullets.append(new_bullet)
	
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
	
	var results = space_state.intersect_shape(query, 512)
	for col in results:
		if col['collider'].is_in_group("hitbox"):
			var enemy = col['collider'].get_parent()
			if not enemy.invincible and not enemy == self:
				enemy.take_damage(damage, self)
				enemy.velocity += (enemy.global_position - global_position).normalized() * force
			
		elif col['collider'].is_in_group("bullet") and deflect_power > 0:
			var bullet = col['collider']
			var target = bullet.source
			if target and target != self:
				bullet.source = self
				bullet.lifetime += 2
				if deflect_power > 1:
					var bullet_speed = bullet.velocity.length()
					bullet.velocity = (target.global_position - bullet.global_position).normalized() * max(50, bullet_speed)*deflect_power
				else:
					bullet.velocity = -bullet.velocity
		
func take_damage(damage, source):
	if invincible:
		return
	
	if !is_in_group("enemy"):
		set_invincibility_time(0.05)
		GameManager.camera.set_trauma(0.6)
	
	if swap_shield_health > 0:
		var shield_damage = min(swap_shield_health, damage)
		print("SHIELD DAMAGE: " + str(shield_damage))
		swap_shield_health -= shield_damage
		damage -= shield_damage
		update_swap_shield()

	health -= damage
	healthbar.value = health
	sprite.modulate = Color.red
	if health <= 0:
		die(source)
		
func set_invincibility_time(time):
	invincible = true
	invincibility_timer = time

func init_healthbar():
	if is_boss:
		health *= 2
	healthbar.max_value = health
	healthbar.value = health
	healthbar.rect_scale.x = health / 200.0
	

func toggle_swap(state):
	if state == true and !GameManager.swappable:
		return
		
	about_to_swap = state
	if(about_to_swap):
		GameManager.lerp_to_timescale(0.1)
		slow_audio.play()
		swap_cursor.moon_visible = true
		choose_swap_target()
	else:
		GameManager.camera.lerp_zoom(1)
		GameManager.lerp_to_timescale(1)
		
		clear_transcender()
		stopped_audio.stop()
		slow_audio.stop()
		speed_audio.play()
		swap_cursor.moon_visible = false
		swap_cursor.selected_enemy = null
		swap_cursor.emit_selected_enemy_signal(false)
		clear_transcender()
		
func toggle_playerhood(state):
	if state == true:
		remove_from_group("enemy")
		add_to_group("player")
		GameManager.player = self
		GameManager.camera.anchor = self
		GameManager.camera.offset = Vector2.ZERO
		GameManager.camera.lerp_zoom(1)
		GameManager.swap_history.append(name.lstrip('@').substr(0, 3))
		GameManager.update_variety_bonus()
		attack_cooldown = -1
		special_cooldown = -1
		time_since_controlled = 0
		
		if is_boss and enemy_evolution_level > GameManager.evolution_level:
			GameManager.evolution_level = enemy_evolution_level #Does not update UI
			capturing_boss = true
			set_invincibility_time(1.25)
			boss_capture_timer = 1.25
			target_velocity = Vector2.ZERO
			GameManager.lerp_to_timescale(0.1)
			GameManager.camera.lerp_zoom(0.5)
			swap_cursor.boss.play()
	else:
		remove_from_group("player")
		add_to_group("enemy")
		attack_cooldown = max(attack_cooldown, 1)
		special_cooldown = max(special_cooldown, 1)
		
	toggle_enhancement(state)
		
func toggle_enhancement(state):
	toggle_light(state)
	
	if state == true:
		animplayer.playback_speed = 1 + 0.1*GameManager.evolution_level
	else:
		animplayer.playback_speed = 1
	
	if state or is_boss:
		var lv = max(GameManager.evolution_level, enemy_evolution_level)
		EV_particles.emitting = true
		EV_particles.amount = 8 + 2*lv
		EV_particles.scale_amount = 1.5 + 0.4*lv
		#var c1 = Color.from_hsv(1 - lv*0.033, 0.92, 1.0, 1.0) if state else Color(1, 1, 1, 0.85)
		#var c2 = Color(0.50, 0, 0, 0.85) if state else Color(0.48, 0.72, 0.976, 0.85)
		#EV_particles.color_ramp.set_color(0, c1)
		#EV_particles.color_ramp.set_color(1, c2)
	else:
		EV_particles.emitting = false
		
func toggle_light(is_player):
	if GameManager.level['dark']:
		light_circle.get_parent().visible = true
		if is_player:
			light_circle.texture_scale = 10
			light_circle.energy = 0.8
			light_circle.color = Color.white
			
			light_beam.texture_scale = 0.7
			light_beam.energy = 1
			light_beam.color = Color.white
		else:
			light_circle.get_parent().visible = false
			#light.texture_scale = 3
			#light.energy = 0.6
	else:
		light_circle.get_parent().visible = false

func on_boss_capture():
	invincible = false
	GameManager.spawn_explosion(global_position + Vector2(0, 20), self, 1.5, 100, 500)
	GameManager.camera.set_trauma(0.8, 4)
	GameManager.lerp_to_timescale(1)
	GameManager.camera.lerp_zoom(1)
	GameManager.set_evolution_level(enemy_evolution_level)
	
func add_swap_shield(hp):
	max_swap_shield_health = hp
	swap_shield_health = hp
	
func update_swap_shield():
	if swap_shield_health > 0:
		var health_ratio = swap_shield_health/max_swap_shield_health
		swap_shield.modulate = Color(0.5+health_ratio*0.5, health_ratio, health_ratio, 0.3 + health_ratio*0.7)
	else:
		swap_shield.visible = false;

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
		
func emit_score_popup(value, msg):
	var popup = score_popup.instance().duplicate()
	popup.get_node("Score").text = "+" + str(value)
	popup.get_node("Message").text = ("- " + msg + " -") if len(msg) > 0 else msg
	popup.rect_global_position = global_position + Vector2(0, -40)
	get_node("/root").add_child(popup)

func die(killer = null):
	if dead: return
	
	dead = true
	set_invincibility_time(999)
	attacking = true
	target_velocity = Vector2.ZERO
	GameManager.enemy_count -= 1
	animplayer.play("Die")
	
	if is_boss:
		score *= enemy_evolution_level
		GameManager.cur_boss = null
	
	if is_in_group("enemy"):
		if killer:
			var effective_score = int(score*GameManager.variety_bonus*(1.5 if GameManager.swap_bar.swap_threshold == 0 else 1.0))
			
			if killer == GameManager.player:
				GameManager.increase_score(effective_score)
				emit_score_popup(effective_score, "")
				
			elif time_since_controlled < 2:
				GameManager.increase_score(effective_score*2)
				emit_score_popup(effective_score*2, "CLOSE CALL")
				
			elif killer.time_since_controlled < 2:
				GameManager.increase_score(effective_score*2)
				emit_score_popup(effective_score*2, "TRICKSHOT")
	else:
		GameManager.camera.set_trauma(1, 4)
		GameManager.lerp_to_timescale(0.1)
		GameManager.swap_bar.swap_threshold_penalty = 2
		if not GameManager.swappable:
			actually_die()


func actually_die():
	if is_in_group("enemy"):
		queue_free()
	else:
		dead = true
		GameManager.swappable = false
		GameManager.lerp_to_timescale(0.1)
		#self.visible = false
		GameManager.swap_bar.visible = false
		ScoreDisplay.visible = false
		ScoreLabel.set_text(str(GameManager.total_score))
		death_screen.popup()



