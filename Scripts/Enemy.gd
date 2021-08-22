extends KinematicBody2D

class_name Enemy

enum EnemyType {
	SHOTGUN,
	CHAIN,
	FLAME,
	WHEEL,
	ARCHER,
	EXTERMINATOR,
	SORCERER,
	SABER,
	SHAPESHIFTER,
	UNKNOWN
}

onready var animplayer = $AnimationPlayer
onready var sprite = $Sprite
onready var swap_shield = $ClearMoon
onready var score_popup = load("res://Scenes/ScorePopup.tscn")
onready var transcender_curve = Curve2D.new()
onready var healthbar = $HealthBar
onready var EV_particles = $EVParticles
#onready var astar = self.get_parent().get_node("AStar")
onready var shape = $CollisionShape2D
onready var light_circle = $CharacterLights/Radial
onready var light_beam = $CharacterLights/Directed

onready var attack_cooldown_audio = load('res://Sounds/SoundEffects/relaod.wav')

var enemy_type = EnemyType.UNKNOWN
var score = 0
var health = 100
var max_speed = 100
var mass = 1
var velocity = Vector2.ZERO
var target_velocity = Vector2.ZERO
var accel = 10
var light_color = Color.white
var base_color = Color.white

var is_flashing = false
var flash_timer = 0
var flash_color = Color.white

var facing_left = false
var attacking = false

var is_miniboss = false
var enemy_evolution_level = 0

var max_swap_shield_health = 0
var swap_shield_health = 0

var attack_cooldown = 0
var max_attack_cooldown
var special_cooldown = 0
var max_special_cooldown = 0
var time_since_controlled = 999
var time_since_player_damage = 999

var aim_direction = Vector2.ZERO
var lock_aim = false

var flip_offset = 0
var bullet_spawn_offset = 0
var foot_offset = 0

var immobile = false
var shoot_through = []

var stunned = false
var stun_timer = 0

var invincible = false
var invincibility_timer = 0

var capturing_boss = false
var boss_capture_timer = 0

var idle_anim = "Idle"
var walk_anim = "Walk"

var dead = false
var force_swap = false
var death_timer = 0


func _ready():
	#GameManager.audio = get_node("/root/Level/AudioStreamPlayer")
	foot_offset = Vector2(0, get_node("CollisionShape2D").position.y)
	update_swap_shield()
	GameManager.connect('on_level_ready', self, 'on_level_ready')	
	
func on_level_ready():
	toggle_light(GameManager.level['dark'] and is_in_group('player'))
	if is_in_group('player'):
		#toggle_playerhood(true)
		pass

func _physics_process(delta):
	if dead and is_in_group("player"):
		death_timer -= delta
		if death_timer < 0:
			death_timer = 99999999
			actually_die()
			
	if not dead and not stunned:
		misc_update(delta)
		
	if not is_in_group("enemy"):
		if capturing_boss:
			boss_capture_timer -= 0.016
			GameManager.camera.trauma = 0.3
			
			if boss_capture_timer < 0 or dead:
				capturing_boss = false
				on_boss_capture()
				
		if not capturing_boss:
			if not dead and not stunned:
				player_move(delta)
				
				if not lock_aim:
					aim_direction = (get_global_mouse_position() - global_position).normalized()
					if light_beam:
						light_beam.rotation = aim_direction.angle() - PI/2
				
			if GameManager.swapping:
				GameManager.choose_swap_target(delta)
			else:
				if not dead and not stunned:
					player_action()
					
				if GameManager.can_swap and Input.is_action_just_pressed("swap"):
					GameManager.toggle_swap(true)
		
		
	else:
		time_since_controlled += delta
		time_since_player_damage += delta
		if is_instance_valid(GameManager.player) and not GameManager.player_hidden and GameManager.player != self and not dead and not stunned:
			ai_move()
			ai_action()
	
	if attack_cooldown >= 0 and attack_cooldown < delta and is_in_group('player'):
		GameManager.attack_cooldown_SFX.stream = attack_cooldown_audio
		GameManager.attack_cooldown_SFX.play()
		
	if special_cooldown >= 0 and special_cooldown < delta and is_in_group('player'):
		#GameManager.attack_cooldown_SFX.stream = attack_cooldown_audio
		#GameManager.attack_cooldown_SFX.play()
		pass

	attack_cooldown -= delta
	special_cooldown -= delta
	
	if stunned:
		stun_timer -= delta
		update_stun_effect(delta)
		if stun_timer < 0:
			stunned = false
			animplayer.play()
	else:
		animate()
	
	if invincible:
		invincibility_timer -= delta
		if invincibility_timer < 0:
			invincible = false
	
	update_flash(delta)
	
	if not immobile:
		move(delta)
	else:
		velocity = Vector2.ZERO
	
	
func move(delta):
	velocity = lerp(velocity, target_velocity.normalized()*max_speed, accel*delta)	
	velocity = move_and_slide(velocity)

func player_move(_delta):
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
		play_animation(idle_anim)
	elif !attacking:
		play_animation(walk_anim)
		
	#sprite.modulate = lerp(sprite.modulate, base_color, 0.2)
	
func play_animation(anim_name):
		if not dead and not stunned:
			animplayer.play(anim_name)
		
func shoot_bullet(vel, damage = 10, mass_ = 0.25, lifetime = 10, type = "pellet", stun = 0, size = Vector2.ONE):
	var bullet = Projectile.shoot_bullet(self, global_position + aim_direction*bullet_spawn_offset, vel, damage, mass_, lifetime, type, stun, size)
	bullet.ignored = shoot_through
	return bullet
	
func melee_attack(collider, damage = 10, force = 50, deflect_power = 0, stun = 0):
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
				enemy.take_damage(damage, self, stun)
				enemy.velocity += (enemy.global_position - global_position).normalized() * force / enemy.mass
				
				if not enemy.is_in_group("bloodless"):
					GameManager.spawn_blood(enemy.global_position, (enemy.global_position - global_position).angle(), pow(force, 0.5)*30, damage*0.75)
				
		elif col['collider'].is_in_group("bullet") and deflect_power > 0:
			var bullet = col['collider']
			if bullet.deflectable:
				var target = bullet.source
				var deflect_case
				if is_instance_valid(target):
					if target == self:
						deflect_case = 0
					elif deflect_power == 1:
						deflect_case = 1
					else:
						deflect_case = 2
				else:
					deflect_case = 1
					
				if deflect_case > 0:
					bullet.source = self
					bullet.lifetime += 1
					bullet.stun = max(bullet.stun, stun*0.5)
					if deflect_case > 1:
						bullet.lifetime += 2
						var bullet_speed = bullet.velocity.length()
						var dir = (target.global_position - bullet.global_position).normalized() if is_instance_valid(target) else -bullet.velocity/bullet_speed
						bullet.velocity =  dir*max(50, bullet_speed)*deflect_power
					else:
						bullet.velocity = -bullet.velocity*deflect_power
				

		
func take_damage(damage, source, stun = 0):
	if invincible:
		return
	
	if is_in_group("player"):
		#set_invincibility_time(0.05)
		GameManager.camera.set_trauma(0.4)
		
	elif source == GameManager.true_player:
		time_since_player_damage = 0
		
	if swap_shield_health > 0:
		var shield_damage = min(swap_shield_health, damage)
		swap_shield_health -= shield_damage
		damage -= shield_damage
		if swap_shield_health <= 1:
			swap_shield_health = 0
			
		update_swap_shield()
		
	if stun > 0:
		target_velocity = Vector2.ZERO
		stunned = true
		stun_timer = max(stun_timer, stun)
		animplayer.stop()

	health -= damage
	healthbar.value = health
	sprite.material.set_shader_param('color', Color(1, 1, 1, 1))
	flash_timer = 0.066
	is_flashing = true
	
	if health <= 0:
		die(source)
		
func set_invincibility_time(time):
	invincible = true
	invincibility_timer = time

func init_healthbar():
	if is_miniboss:
		health *= 2
	healthbar.max_value = health
	healthbar.value = health
	healthbar.rect_scale.x = health / 200.0
	
		
func toggle_playerhood(state):
	toggle_light(state)
	
	if state == true:
		if is_in_group('enemy'):
			remove_from_group("enemy")
		add_to_group("player")
		attack_cooldown = -1
		special_cooldown = -1
		time_since_controlled = 0
		GameManager.on_swap(self)
		toggle_enhancement(true)
		
		if is_miniboss and enemy_evolution_level > GameManager.evolution_level:
			GameManager.evolution_level = enemy_evolution_level #Does not update UI
			capturing_boss = true
			set_invincibility_time(1.25)
			boss_capture_timer = 1.25
			target_velocity = Vector2.ZERO
			GameManager.lerp_to_timescale(0.1)
			GameManager.camera.lerp_zoom(0.5)
			GameManager.world.blood_moon.boss.play()
	else:
		if is_in_group('player'):
			remove_from_group("player")
		add_to_group("enemy")
		attack_cooldown = max(attack_cooldown, 1)
		special_cooldown = max(special_cooldown, 1)
		
func toggle_enhancement(state):
	if state == true:
		animplayer.playback_speed = 1 + 0.1*GameManager.evolution_level
	else:
		animplayer.playback_speed = 1
	
	if state or is_miniboss:
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
	if not swap_shield: return
	if swap_shield_health > 0:
		var health_ratio = swap_shield_health/max_swap_shield_health
		swap_shield.modulate = Color(0.5+health_ratio*0.5, health_ratio, health_ratio, 0.3 + health_ratio*0.7)
	else:
		swap_shield.visible = false;
		
func toggle_selected_enemy(enemy_is_selected):
	if enemy_is_selected:
		emit_signal("toggle_selected_enemy")
	
func update_flash(delta):	
	if is_flashing:
		flash_timer -= delta
		sprite.material.set_shader_param('intensity', 1 if int(flash_timer*15)%2 == 0 else 0)
		if flash_timer < 0:
			is_flashing = false
			sprite.material.set_shader_param('intensity', 0)
			
func update_stun_effect(delta):
	if randf() > 0.93:
		is_flashing = true
		sprite.material.set_shader_param('color', Color(0, 1, 1, 1))
		flash_timer = 0.066
		
func emit_score_popup(value, msg):
	var popup = score_popup.instance().duplicate()
	popup.get_node("Score").text = "+" + str(value)
	popup.get_node("Message").text = ("- " + msg + " -") if len(msg) > 0 else msg
	popup.rect_global_position = global_position + Vector2(0, -40)
	get_node("/root").add_child(popup)
	
func on_bullet_despawn(bullet):
	pass

func die(killer = null):
	if dead: return
	
	dead = true
	set_invincibility_time(999)
	attacking = true
	target_velocity = Vector2.ZERO
	GameManager.enemy_count -= 1
	GameManager.enemies.erase(self)
	death_timer = 0.5
	animplayer.play("Die")
	
	if is_miniboss:
		score *= enemy_evolution_level
		GameManager.cur_boss = null
	
	if is_in_group("enemy"):
		if is_instance_valid(killer):
			var effective_score = int(score*GameManager.variety_bonus*(1.5 if GameManager.swap_bar.swap_threshold == 0 else 1.0))
			var message = ''
			var kill_validity = 2
			
			if killer == GameManager.true_player:
				if GameManager.player_hidden:
					effective_score *= 1.5
					message = 'SHANK!'
				
			elif killer.time_since_controlled < 2:
				effective_score *= 2
				message = 'TRICKSHOT'
				
			elif time_since_controlled < 2:
				effective_score *= 1.5
				message = 'CLOSE CALL'
				kill_validity = 1
				
			elif killer.enemy_type == EnemyType.FLAME and killer.killed_by_player:
				effective_score *= 1.5
				message = 'KABOOM!'
				kill_validity = 1
				
			elif time_since_player_damage < 0.5 and is_instance_valid(killer) and killer.enemy_type == EnemyType.ARCHER:
				effective_score *= 1.5
				message = 'DAMN ARCHERS!'
				kill_validity = 1
				
			elif time_since_player_damage < 2:
				effective_score *= 0.5
				message = 'ASSIST'
				kill_validity = 1
				
			else:
				kill_validity = 0
				
			if kill_validity > 0:
				effective_score = int(effective_score)
				GameManager.increase_score(effective_score)
				emit_score_popup(effective_score, message)
				
				if kill_validity == 2:
					GameManager.kills += 1
					Options.enemy_kills[str(enemy_type)] += 1
				
	else:
		GameManager.camera.set_trauma(1, 16 if GameManager.swapping else 4)
		GameManager.lerp_to_timescale(0.1)
		GameManager.swap_bar.swap_threshold_penalty = 2
		GameManager.enemy_drought_bailout_available = true
		if not GameManager.can_swap:
			death_timer = 0.3
		if is_instance_valid(killer):
			Options.enemy_deaths[str(killer.enemy_type)] += 1
			


func actually_die():
	if is_in_group("enemy"):
		queue_free()
	else:
		dead = true
		GameManager.game_over()



