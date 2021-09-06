extends "res://Scripts/Enemy.gd"

onready var teleport_sprite = $TeleportSprite
onready var bullet_holder = $BulletHolder
onready var cw_ring = $BulletHolder/CW
onready var ccw_ring = $BulletHolder/CCW
onready var deflector_shape = $Deflector/CollisionShape2D
onready var deflector_visual = $Deflector/DeflectorVisual
onready var rev_audio = $RevUpAudio
onready var shoot_audio = $ShootAudio

const pew_sound = preload('res://Sounds/SoundEffects/Zing.wav')
const crack_sound = preload('res://Sounds/SoundEffects/CrispExplosion.wav')

var walk_speed
var shield_power
var bullet_orbit_accel

var walk_speed_levels = [40, 50, 60, 65, 70, 75, 80]
var shield_power_levels = [1200, 400, 500, 600, 700, 800, 900]
var bullet_orbit_accel_levels = [5, 7, 8, 9, 10, 11, 12]

var damage_mult = 1.0
var bullet_production_rate = 0
var min_bullet_orbit_speed = 3
var bullet_formation_speed = 5
var shield_width = PI/2
var bulwark_mode = false
var compact_mode = false
var laser_deflect = false

var shield_active = true
var shield_angle = 0

var retaliating = false
var retaliation_locked = false
var bullet_orbit_speed = min_bullet_orbit_speed
var target_bullet_orbit_speed = 0
var expulsion_queue = []
var expulsion_timer = 0
var formation_timer = 0
var lerped_player_pos = Vector2.ZERO
var ai_bullet_speed_threshold = 0

var teleport_start_point = Vector2.ZERO
var teleport_end_point = Vector2.ZERO
var charging_tp = false
var tp_next_frame = false
var teleport_timer = 0

var nearby_bullets = []
var captured_bullets = []
var bullet_formation_positions = []
var nearby_enemies = []

var bullet_production_timer = 0
var bullet_reformation_timer = 0
var ai_move_timer = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	enemy_type = EnemyType.EXTERMINATOR
	max_health = 150
	max_attack_cooldown = 1.5
	max_special_cooldown = 1.6
	flip_offset = 24
	mass = 1.5
	healthbar.max_value = health
	init_healthbar()
	score = 100
	get_node('Deflector').collision_layer = 8
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	shield_power = shield_power_levels[level]
	bullet_orbit_accel = bullet_orbit_accel_levels[level]
	damage_mult = 1.3 + 0.2*level
	
	bullet_production_rate = 0
	min_bullet_orbit_speed = 3
	bullet_formation_speed = 5
	shield_width = PI/2
	deflector_visual.texture = load('res://Art/Shields/QuarterCircle.png')
	bulwark_mode = false
	compact_mode = false
	retaliation_locked = false
	laser_deflect = false
	
	
	if state  == true:
		bullet_production_rate = 1.5*GameManager.player_upgrades['improvised_projectiles']
		
		min_bullet_orbit_speed += 3*GameManager.player_upgrades['high-energy_orbit']
		
		shield_width += PI*0.4*GameManager.player_upgrades['exposed_coils']
		if GameManager.player_upgrades['exposed_coils'] == 1:
			deflector_visual.texture = load('res://Art/Shields/Circle_162.png')
		elif GameManager.player_upgrades['exposed_coils'] > 1:
			deflector_visual.texture = load('res://Art/Shields/Circle_234.png')
			
		if GameManager.player_upgrades['impulse_accelerator'] > 0:
			compact_mode = true
			if GameManager.player_upgrades['high-energy_orbit'] > 0:
				bullet_formation_speed = 10
		
		if GameManager.player_upgrades['bulwark_mode'] > 0:
			bulwark_mode = true
			bullet_orbit_accel *= 2
		
		if GameManager.player_upgrades['particulate_screen'] > 0:
			laser_deflect = true
			
	if not compact_mode:
		get_node("BulletHolder").position = Vector2.ZERO
		shoot_audio.stream = pew_sound
	else:
		shoot_audio.stream = crack_sound
		
	bullet_orbit_speed = min_bullet_orbit_speed
	if retaliating:	
		toggle_retaliation(false)
		
	.toggle_enhancement(state)

func misc_update(delta):
	deflector_visual.rotation = shield_angle
	
	if is_player and not retaliating:
		bullet_production_timer -= delta*bullet_production_rate
		if bullet_production_timer < 0:
			bullet_production_timer = 1
			shoot_bullet(Vector2.ZERO, 10, 0.25, 3)
	
	for b in captured_bullets:
		if is_instance_valid(b):
			b.lifetime = 3
			b.velocity = Vector2.ZERO
	
	if retaliating:
		retaliate(delta)
		if compact_mode and not bulwark_mode and retaliation_locked and bullet_orbit_speed > 6.5:
			retaliation_locked = false
					
	elif bullet_orbit_speed > min_bullet_orbit_speed:
		bullet_orbit_speed = max(bullet_orbit_speed - 4*delta, 3)
	
	cw_ring.rotation += bullet_orbit_speed*delta
	ccw_ring.rotation -= bullet_orbit_speed*delta
	if formation_timer > 0:
		formation_timer -= delta
		for i in range(min(len(captured_bullets), len(bullet_formation_positions))):
			if is_instance_valid(captured_bullets[i]):
				captured_bullets[i].position = lerp(captured_bullets[i].position, bullet_formation_positions[i], bullet_formation_speed*delta)
		
	if shield_active:
		apply_shield_effects(delta)	
	
	if charging_tp:
		teleport_timer -= delta
		if teleport_timer < 0:
			teleport()
			
	ai_move_timer -= delta


func player_action():
	shield_angle = aim_direction.angle()
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0 and not attacking:
		Util.remove_invalid(captured_bullets)
		if len(captured_bullets) > 0:
			toggle_retaliation(true)
		
	elif not Input.is_action_pressed("attack1") and retaliating and not retaliation_locked:
		toggle_retaliation(false)
	
	if Input.is_action_pressed("attack2"):
		GameManager.camera.lerp_zoom(2)
	else:
		GameManager.camera.lerp_zoom(1)
		
	if Input.is_action_just_released("attack2") and special_cooldown < 0 and not attacking:
		start_teleport(get_global_mouse_position())

func ai_move():
	if ai_move_timer < 0:
		ai_move_timer = 1 + randf()*3
		if randf() < 0.5 or target_velocity == Vector2.ZERO:
			target_velocity = Vector2(randf()-0.5, randf()-0.5)*100
		else:
			target_velocity = Vector2.ZERO

func ai_action():
	aim_direction = GameManager.player.global_position - global_position
	lerped_player_pos = lerp(lerped_player_pos, GameManager.player.global_position, 0.1)
	
	var delta_angle = Util.signed_wrap(aim_direction.angle() - shield_angle)
	shield_angle = Util.signed_wrap(shield_angle + sign(delta_angle)/60)
	
	if not retaliating:
		if randf() < 0.002 * len(captured_bullets)  and aim_direction.length() < 250:
			ai_bullet_speed_threshold = 6 + randf()*10
			toggle_retaliation(true)
	else:
		if bullet_orbit_speed > ai_bullet_speed_threshold:
			toggle_retaliation(false)
		
		
#	if randf() < 0.002 and special_cooldown < 0 and not retaliating:
#		for i in range(len(GameManager.player_bullets) > 0):
#			var bullet = GameManager.player_bullets[int(randf()*len(GameManager.player_bullets))]
#			if is_instance_valid(bullet) and bullet.source == GameManager.player:
#				var point = bullet.global_position + bullet.velocity
#
#				if(GameManager.is_point_in_bounds(point)):
#					start_teleport(point)
#					special_cooldown = 8
#					break
				
	if special_cooldown < 0 and not immobile and aim_direction.length() < 30:
		special_cooldown = 8
		var point = GameManager.random_map_point()
		if point:
			start_teleport(point)
		
		
func toggle_retaliation(state):
	if dead:
		return
		
	retaliating = state
	attacking = state
	#shield_active = !state
	deflector_visual.material.set_shader_param('color', Vector3(1, 0.3, 0.4) if state else Vector3(0.5, 0.5, 1))
	expulsion_timer = -1
	calculate_bullet_formation()
	bullet_reformation_timer = 0.5
	
	if state == true:
		rev_audio.play()
		expulsion_queue = range(len(captured_bullets))
		expulsion_queue.shuffle()
		if bulwark_mode:
			attacking = true
			#lock_aim = true
			override_speed = 0
			mass = 10
			retaliation_locked = true
			expulsion_timer = 0.4/(GameManager.player_upgrades['high-energy_orbit'] + 1)
			play_animation('Entrench')
			get_node('Hitbox').position.x = -9*sign(aim_direction.x)
			
		elif compact_mode:
			retaliation_locked = true
			
	else:
		rev_audio.stop()
		if compact_mode:
			expel_compacted_bullets()
			bullet_holder.position = Vector2.ZERO
			
		if mass > 1.5: #effectively if bulwark_mode, still works if player swaps out
			attacking = false
			lock_aim = false
			override_speed = null
			mass = 1.5
			get_node('Hitbox').position.x = 0


func retaliate(delta):
	#rev_audio.pitch_scale = 0.9 + bullet_orbit_speed/30.0
	
	if compact_mode:
		get_node("BulletHolder").position = lerp(get_node("BulletHolder").position, aim_direction.normalized()*50, bullet_formation_speed*delta)
		bullet_reformation_timer -= delta
		if bullet_reformation_timer < 0:
			bullet_reformation_timer = 0.5
			calculate_bullet_formation()
		
	if bullet_orbit_speed < 6:
		bullet_orbit_speed = bullet_orbit_speed + bullet_orbit_accel*delta
	else:
		bullet_orbit_speed = bullet_orbit_speed + bullet_orbit_accel*0.25*delta
		
		if not compact_mode:
			expulsion_timer -= delta
			if expulsion_timer < 0:
				expulsion_timer = 0.5/(bullet_orbit_speed-3)
				while not expulsion_queue.empty():
					var i = expulsion_queue.pop_back()
				
					if i < len(captured_bullets) and is_instance_valid(captured_bullets[i]):
						shoot_audio.play()
						
						var b = captured_bullets[i]
						var dir = (get_global_mouse_position() if is_player else lerped_player_pos) - b.global_position
						var width = 12 if b.is_in_group('death orb') else b.scale.x*4
						var damage = 100 if b.is_in_group('death orb') else b.damage*damage_mult
						var kb = 100*width/6.0 * (3 if bulwark_mode else 1)
						var explosion_size = sqrt(damage)/10 if bulwark_mode else 0
						
						LaserBeam.shoot_laser(b.global_position, dir, width, self, damage, kb, 0, true, 'rail', explosion_size, damage/2, damage*5, false, is_player)
						b.despawn()
						captured_bullets[i] = null
						if is_player:
							GameManager.camera.set_trauma(0.4, 10)
						break
				
				if expulsion_queue.empty():
					toggle_retaliation(false)	
					
func expel_compacted_bullets():
	shoot_audio.play()
	var dir = aim_direction.normalized()
	Util.remove_invalid(captured_bullets)
	GameManager.camera.set_trauma(min(bullet_orbit_speed/12.0, 1.0))
	
	if bullet_orbit_speed < 16:
		var center_dist = 50
		for i in range(len(captured_bullets)):
			var b = captured_bullets[i]
			if not b.is_in_group('death orb'):
				b.damage *= damage_mult
				
			b.velocity = dir*bullet_orbit_speed*70*(1.0 + (((b.global_position - global_position).length() - center_dist)/30.0))
			b.spectral = false
			
			if bulwark_mode:
				if not b.is_in_group('death orb') and not b.is_in_group('flak bullet'):
					b.explosion_size = b.scale.x*0.4
					b.explosion_damage = b.damage*0.5
					b.explosion_kb = b.mass*800
			
			Util.reparent_to(b, GameManager.projectiles_node)
			captured_bullets[i] = null
	else:
		var damage = 0
		var width = 1
		retaliating = true #Dumb hadk
		for b in captured_bullets:
			damage += 100 if b.is_in_group('death orb') else b.damage
			if b.is_in_group('death orb'):
				width += 8
			elif b.is_in_group('flak bullet'):
				width += 3
			else:
				width += 1
			b.despawn()
			
		if width > 16:
			width = 12 + sqrt(width)
			
		retaliating = false #End dumb hack
		LaserBeam.shoot_laser(bullet_holder.global_position, dir, width, self, damage, 1000, 0, true, 'rail')
		 
	if bullet_orbit_speed > 6:
		GameManager.spawn_explosion(bullet_holder.global_position, self, 0.4, 20, 300)
		
	captured_bullets = []
	velocity -= dir*bullet_orbit_speed*50
	
	
func start_teleport(point):
	teleport_end_point = point
	if GameManager.is_point_in_bounds(point + foot_offset):
		charging_tp = true
		attacking = true
		shield_active = false
		deflector_visual.visible = false
		
		special_cooldown = 1.6
		teleport_timer = 0.4
		lock_aim = true
		override_speed = 0
		play_animation('Vanish')
	
func teleport():
	charging_tp = false
	teleport_start_point = global_position
	
	teleport_sprite.global_position = teleport_start_point
	teleport_sprite.visible = true
	teleport_sprite.flip_h = facing_left
	teleport_sprite.offset.x = 11 if facing_left else -13
	teleport_sprite.play("Vanish")
	teleport_sprite.frame = 4
	
	global_position = teleport_end_point
	invincible = true
	attacking = true
	play_animation("Appear")
	teleport_sprite.global_position = teleport_start_point
	
func apply_shield_effects(delta):
	if len(nearby_bullets) > 0:
		Util.remove_invalid(nearby_bullets)
		var formation_update_needed = false
		
		for i in range(len(nearby_bullets)):
			var b = nearby_bullets[i]
			var bullet_speed = b.velocity.length()
			
			if bullet_speed > 5 or retaliating:
				var angle = (b.global_position - global_position).angle() - shield_angle
				if angle > PI:
					angle -= 2*PI
				elif angle < -PI:
					angle += 2*PI
					
				if abs(angle) < shield_width/2:
					var shield_bonus = 1.5 if b.is_in_group('death orb') else 1
					if retaliating:
						shield_bonus *= 0.6
					b.velocity -= (b.velocity/bullet_speed) * min(bullet_speed, shield_power*shield_bonus*delta)
				
			else:
				if b.is_in_group('death orb') and is_instance_valid(b.source):
					b.source.orbs[b.source.orbs.find(b)] = null
					
				b.source = self
				b.deflectable = false
				b.spectral = true
				captured_bullets.append(b)
				b.modulate = Color(0.7, 0.2, 1)
				nearby_bullets[i] = null
				Util.reparent_to(b, cw_ring)
				formation_update_needed = true
				
		if formation_update_needed:
			calculate_bullet_formation()
		
	Util.remove_invalid(nearby_enemies)	
	for e in nearby_enemies:
		var angle = (e.global_position - global_position).angle() - shield_angle
		if angle > PI:
			angle -= 2*PI
		elif angle < -PI:
			angle += 2*PI
			
		if abs(angle) < PI/4:
			e.velocity -= e.velocity*0.5
				
				
func calculate_bullet_formation():
	Util.remove_invalid(captured_bullets)
	
	var length = len(captured_bullets)
	if length == 0:
		return
	
	var circle_radii
	if retaliating and compact_mode:
		var r = 7.0/bullet_orbit_speed
		circle_radii = [5*r, 10*r, 15*r]
	else:
		circle_radii = [30, 40, 50]
		
	var circle_capacities = [16, 24, 32]
	if length > 72:
		for i in range(length - 72):
			circle_capacities[i%3] += 1
	
	var circle_counts = [
		min(length, circle_capacities[0]),
		clamp(length - circle_capacities[0], 0, circle_capacities[1]),
		max(length - circle_capacities[0] - circle_capacities[1], 0)
	]
	
	var delta_angles = [
		2*PI/circle_counts[0],
		2*PI/circle_counts[1] if circle_counts[1] > 0 else 0,
		2*PI/circle_counts[2] if circle_counts[2] > 0 else 0
	]
	
	var init_angle = captured_bullets[0].position.angle()
	var cur_angle = init_angle
	
	bullet_formation_positions = []
	for c in range(3):
		for i in range(circle_counts[c]):
			var b = captured_bullets[len(bullet_formation_positions)]
			if c == 1 and b.get_parent() != ccw_ring:
				Util.reparent_to(b, ccw_ring)
			elif c != 1 and b.get_parent() != cw_ring:
				Util.reparent_to(b, cw_ring)
				
			bullet_formation_positions.append(Vector2(cos(cur_angle), sin(cur_angle)) * circle_radii[c])
			cur_angle += delta_angles[c]
			
	formation_timer = 0.7
	
func on_laser_deflection(impact_point, dir, width, source, damage, kb, stun, piercing, style, explosion_size, explosion_damage, explosion_kb):
	if not shield_active: return false
	
	var normal = (impact_point - global_position).normalized()
	var normal_angle = (impact_point - global_position).angle()
	var rel_angle = Util.signed_wrap(normal_angle - shield_angle)
		
	if abs(rel_angle) < shield_width/2:
		if laser_deflect:
			var reflection_angle = Util.signed_wrap(normal_angle - ((-dir).angle() - normal_angle))
			
			for i in range(3):
				var beam_angle = reflection_angle + (0.5-randf())*PI/3
				var beam_dir = Vector2(cos(beam_angle), sin(beam_angle))
				LaserBeam.shoot_laser(impact_point, beam_dir, width/2.0, self, damage/3, kb/2, stun, piercing, style, explosion_size/2.0, explosion_damage/3, explosion_kb/2.0, true)
		
		else:
			LaserBeam.shoot_laser(impact_point + dir, (dir + normal/3).normalized(), width/2.0, source, damage/2, kb/2, stun, piercing, style, explosion_size/2.0, explosion_damage/3, explosion_kb/2.0, true)
			
		return true
	else:
		return false
		
	
func area_deflect():
	if is_player:
		GameManager.camera.set_trauma(0.5, 5)
		
	Violence.melee_attack(self, deflector_shape, 20, 2000, 3)
	
func on_bullet_despawn(b):
	if not retaliating and b in captured_bullets:
		captured_bullets.erase(b)
		call_deferred('calculate_bullet_formation')

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func take_damage(damage, source, stun = 0):
	.take_damage(damage, source, stun)
	if dead or stunned:
		teleport_sprite.visible = false
		charging_tp = false
		

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Appear" or anim_name == "Attack":
		lock_aim = false
		override_speed = null
		attacking = false
		shield_active = true
		deflector_visual.visible = true
		invincible = false
		
	elif anim_name == 'Entrench':
		retaliation_locked = false
		
	elif anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()

func _on_Deflector_area_entered(area):
	if area.is_in_group("bullet") or area.is_in_group("death orb"):
		if area.is_in_group("death orb"):
			area = area.get_parent()
		if area.deflectable:
			nearby_bullets.append(area)
	elif area.is_in_group("hitbox") and area.get_parent() != self:
		nearby_enemies.append(area.get_parent())
		
func _on_Deflector_area_exited(area):
	if area.is_in_group("bullet") or area.is_in_group("death orb"):
		if area.is_in_group("death orb"):
			area = area.get_parent()
		nearby_bullets.erase(area)
		
		#if area.velocity.x == 0 and area.velocity.y == 0:
		#	area.despawn()
	elif area.is_in_group("hitbox"):
		nearby_enemies.erase(area.get_parent())

func _on_Timer_timeout():
	invincible = false



