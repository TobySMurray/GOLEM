extends Enemylike
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

#onready var transcender_curve = Curve2D.new()
onready var healthbar = $EnemyFX/HealthBar
onready var EV_particles = $EnemyFX/EVParticles
#onready var astar = self.get_parent().get_node("AStar")
onready var shape = $CollisionShape2D
onready var light_circle = $EnemyFX/CharacterLights/Radial
onready var light_beam = $EnemyFX/CharacterLights/Directed
onready var gun_particles = $EnemyFX/GunParticles

onready var attack_cooldown_audio = load('res://Sounds/SoundEffects/relaod.wav')

var score = 0

var attacking = false
var attack_cooldown = 0
var max_attack_cooldown = 0
var attack_cooldown_audio_preempt = 0

var special_cooldown = 0
var max_special_cooldown = 0

var is_miniboss = false
var enemy_evolution_level = 0

var time_since_player_damage = 999

var lock_aim = false

var bullet_spawn_offset = 0
var foot_offset = 0

var immobile = false
var shoot_through = []

var is_flashing = false
var flash_timer = 0
var flash_color = Color.white

var idle_anim = "Idle"
var walk_anim = "Walk"

var force_swap = false

var berserk = false
var last_stand = false


func _ready():
	#GameManager.audio = get_node("/root/Level/AudioStreamPlayer")
	foot_offset = Vector2(0, get_node("CollisionShape2D").position.y)
	update_swap_shield()
	GameManager.connect('on_level_ready', self, 'on_level_ready')	
	GameManager.connect('on_swap', self, 'on_swap')
	
func on_level_ready():
	toggle_light(GameManager.level['dark'] and is_player)

func _physics_process(delta):	
	if not dead and not stunned:
		misc_update(delta)
		
	if is_player:	
		if attack_cooldown >= attack_cooldown_audio_preempt and (attack_cooldown - attack_cooldown_audio_preempt) < delta:
			GameManager.attack_cooldown_SFX.stream = attack_cooldown_audio
			GameManager.attack_cooldown_SFX.play()
		
		if not GameManager.capturing_boss:
			if not dead and not stunned:
				player_move(delta)
				
				if not lock_aim:
					aim_direction = (get_global_mouse_position() - global_position).normalized()
					if light_beam:
						light_beam.rotation = aim_direction.angle() - PI/2
				
				if not GameManager.swapping:
					player_action()
					
	else:
		if is_instance_valid(GameManager.player) and not GameManager.player_hidden and GameManager.player != self and not dead and not stunned:
			ai_move()
			ai_action()
			
		time_since_controlled += delta
		time_since_player_damage += delta
		if GameManager.player_upgrades['scorn'] > 0 and not GameManager.player_hidden and swap_shield_health < 1 and time_since_player_damage > 2:
			max_swap_shield_health = max(max_swap_shield_health, 1)
			swap_shield_health = 1
			update_swap_shield()
		
	if special_cooldown >= 0 and special_cooldown < delta and is_player:
		#GameManager.attack_cooldown_SFX.stream = attack_cooldown_audio
		#GameManager.attack_cooldown_SFX.play()
		pass

	attack_cooldown -= delta
	special_cooldown -= delta
	invincibility_timer -= delta
	update_flash(delta)
	
	if stunned:
		stun_timer -= delta
		update_stun_effect(delta)
		if stun_timer < 0:
			stunned = false
			animplayer.play()
	else:
		animate()
	
	if not immobile:
		move(delta)
	else:
		velocity = Vector2.ZERO

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
		
	target_velocity = input.normalized()
	
func misc_update(delta):
	pass
		
func player_action():
	pass
	
func ai_move():
	target_velocity = Vector2.ZERO
	
func ai_action():
	pass	
	
func on_swap():
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
	var bullet = Violence.shoot_bullet(self, global_position + aim_direction*bullet_spawn_offset, vel, damage, mass_, lifetime, type, stun, size)
	bullet.ignored = shoot_through
	return bullet
					
func take_damage(damage, source, stun = 0):
	if invincible:
		return
	
	if is_player:
		#set_invincibility_time(0.05)
		GameManager.camera.set_trauma(0.4)
		
	elif source == GameManager.true_player:
		time_since_player_damage = 0
		if not GameManager.controlling_boss and source.berserk:
			GameManager.swap_bar.control_timer = max(GameManager.swap_bar.control_timer - damage/20.0, 15)
		
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

func init_healthbar():
	if is_miniboss:
		max_health *= 2
	health = max_health
	healthbar.max_value = health
	healthbar.value = health
	healthbar.rect_scale.x = health / 200.0
	
		
func toggle_playerhood(state):
	.toggle_playerhood(state)
	toggle_light(state)
	
	if state == true:
		attack_cooldown = -1
		special_cooldown = -1
		time_since_controlled = 0
		#GameManager.on_swap(self)
		toggle_enhancement(true)
		
		if GameManager.player_upgrades['fear'] > 0:
			var missing_health = healthbar.max_value - health
			health = healthbar.max_value
			healthbar.value = health
			
		if GameManager.player_upgrades['efficiency'] > 0:
			var sacrificed_health = float(health)/healthbar.max_value - 0.25
			if sacrificed_health > 0:
				take_damage(healthbar.max_value*sacrificed_health, null)
				var score_bonus = int(score*sacrificed_health)
				GameManager.increase_score(score_bonus)
				emit_score_popup(score_bonus, 'SACRIFICE')
			
					
		if is_miniboss and enemy_evolution_level > GameManager.evolution_level:
			GameManager.evolution_level = enemy_evolution_level #Does not update UI
			GameManager.capturing_boss = true
			GameManager.boss_capture_timer = 1.25
			invincible = true
			target_velocity = Vector2.ZERO
			GameManager.lerp_to_timescale(0.1)
			GameManager.camera.lerp_zoom(0.5)
			GameManager.world.blood_moon.boss_audio.play()
	else:
		attack_cooldown = max(attack_cooldown, 1)
		special_cooldown = max(special_cooldown, 1)
		if last_stand:
			die()
		
func toggle_enhancement(state):
	print("toggled enhancement for " + name)
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
		
	berserk = false
	if state:
		if GameManager.player_upgrades['revelry'] > 0 and GameManager.swap_bar.control_timer >= 15:
			max_speed *= 1.33
			max_attack_cooldown *= 0.66
			max_special_cooldown *= 0.66
			berserk = true
		
		
func toggle_light(is_player):
	if not light_circle or not light_beam:
		return
		
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
		swap_shield.visible = true;
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

func die(killer = null):
	if dead: return
	.die()
	
	attacking = true
	GameManager.enemy_count -= 1
	GameManager.enemies.erase(self)
	
	if is_miniboss:
		score *= enemy_evolution_level
		GameManager.cur_boss = null
	
	if not is_player:
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
				
			elif killer.is_in_group('enemy') and killer.enemy_type == EnemyType.FLAME and killer.killed_by_player:
				effective_score *= 1.5
				message = 'KABOOM!'
				kill_validity = 1
				
			elif killer.is_in_group('enemy') and time_since_player_damage < 0.5 and is_instance_valid(killer) and killer.enemy_type == EnemyType.ARCHER:
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
				#GameManager.hitstop(0.06)
				
				if kill_validity == 2:
					GameManager.kills += 1
					Options.enemy_kills[str(enemy_type)] += 1
				
	else:
		GameManager.camera.set_trauma(1, 16 if GameManager.swapping else 4)
		GameManager.lerp_to_timescale(0.1)
		GameManager.swap_bar.threshold_death_penalty = 2
		GameManager.enemy_drought_bailout_available = true
		if not GameManager.can_swap or last_stand:
			GameManager.can_swap = false
			death_timer = 0.3
		if is_instance_valid(killer) and killer.is_in_group('enemy') and killer.enemy_type != EnemyType.UNKNOWN:
			Options.enemy_deaths[str(killer.enemy_type)] += 1
			


func actually_die():
	if last_stand:
		GameManager.spawn_explosion(global_position, self, 1, 100, 1000)

	.actually_die()



