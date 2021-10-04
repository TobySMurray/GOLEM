extends Boss

const EnemyPillar = preload('res://Scenes/EnemyPillar.tscn')

enum {
	INACTIVE,
	IDLE,			# Decrease distance if player is far, else do nothing
	ALIGN,			# Move toward cardinal alignment with player to set up CARDINAL_WAVE, and decrease distance if player is far away
	TELEGRAPH_APPROACH,
	APPROACH,		# Rapidly move directly toward player in preparation for DISCOMBOBULATE
	DISCOMBOBULATE, # Dash from one side of the player to the other a random number of times before PUNCHing
	TELEGRAPH_RAM,
	RAM,			# Charge toward player in straight line at high speed, dealing damage on contact. Can collide with pillars
	PUNCH,			# Attack horizontally, breaks pillars and opportunity to stagger during windup
	WAVE_DASH,		# Dash to the other side of the player before emitting a cardinal wave (phase 2)
	CARDINAL_WAVE,	# Smash ground and emit an explosion wave in a cardinal direction toward the player
	TELEGRAPH_PILLAR
	PILLAR_WAVE,	# Smash ground and send a number of explosion waves toward random points, spawning enemy pillars at their terminus
	TELEGRAPH_VOLLEY,
	DIAGONAL_VOLLEY,# Fire a spread of bullets starting along the diagonals, and fanning out until only the cardinals are safe
	STAGGER,		# Briefly stop actions and allow player possession
	PLAYER			# Controlled by the player
}

const pillar_patterns = [
	{
		'enemies': [Enemy.EnemyType.SHOTGUN, Enemy.EnemyType.SHOTGUN],
		'offsets': [Vector2(-0.5, 0), Vector2(0.5, 0)],
		'weight': 1
	},
	{
		'enemies': [Enemy.EnemyType.WHEEL, Enemy.EnemyType.WHEEL],
		'offsets': [Vector2(0.866, 0.5)*0.8, Vector2(-0.866, 0.5)*0.8],
		'weight': 1
	},
	{
		'enemies': [Enemy.EnemyType.CHAIN, Enemy.EnemyType.FLAME],
		'offsets': [Vector2(0.4, 0.4), Vector2(-0.4, -0.4)],
		'weight': 0.5
	},
	{
		'enemies': [Enemy.EnemyType.FLAME, Enemy.EnemyType.CHAIN],
		'offsets': [Vector2(-0.4, 0.4), Vector2(0.4, -0.4)],
		'weight': 0.5
	},
	{
		'enemies': [Enemy.EnemyType.ARCHER],
		'offsets': [Vector2(0.866, -0.5)*0.9],
		'weight': 0.25
	},
	{
		'enemies': [Enemy.EnemyType.ARCHER],
		'offsets': [Vector2(-0.866, -0.5)*0.9],
		'weight': 0.25
	},
	{
		'enemies': [Enemy.EnemyType.EXTERMINATOR, Enemy.EnemyType.EXTERMINATOR],
		'offsets': [Vector2(0, 0.5), Vector2(0, -0.5)],
		'weight': 0.5
	},
	{
		'enemies': [Enemy.EnemyType.SORCERER],
		'offsets': [Vector2(0, -0.8)],
		'weight': 0.5
	}
]

onready var eye_particles = $EyeParticles
onready var sight_raycast = $SightRaycast
onready var punch_collider = $PunchCollider/CollisionShape2D
onready var grind_particles = $Sparks

const MAX_DIST = 250
const MIN_DIST = 100
var target_dist = MAX_DIST

var eye_pos = Vector2.ZERO
var foot_pos = Vector2.ZERO
var aim_dir = Vector2.RIGHT

var arena_radius = 270

var pillars = []
var pillar_count = 0
var cur_pillar_pattern = null

var arena_enemies = []
var arena_enemy_count = 0

var pillar_cooldown = 5
var ram_cooldown = 0

var stagger_resists = 0
var super_moves_used = 0
var super_move_thresholds = [0.66, 0.33, 0]

func _ready():
	flip_offset = -30
	swap_shield_health = 3
	set_state(INACTIVE)
	init_healthbar()
	
func _physics_process(delta):
	Util.remove_invalid(arena_enemies)
	arena_enemy_count = len(arena_enemies)
#	if GameManager.swap_bar:
#		GameManager.swap_bar.set_swap_threshold(0)
		
#	if GameManager.true_player:
#		GameManager.true_player.invincible = true
#		GameManager.true_player.invincibility_timer = 0.1

	eye_pos = global_position + Vector2(0, -18)
	foot_pos = global_position + Vector2(0, 24)
	
	pillar_cooldown -= delta
	ram_cooldown -= delta
		
func enter_state(state):
	if not is_player and not is_instance_valid(GameManager.player) and state != INACTIVE:
		set_state(INACTIVE)
		return
		
	match state:
		INACTIVE:
			pass
		IDLE:
			pass
		ALIGN:
			state_timer = 0.6 - phase*0.1
			accel = 5
			play_animation('Walk')
			var cardinal_dist = max(abs(to_player.y), abs(to_player.x))
			target_dist = min(cardinal_dist - randf()*50, MAX_DIST) if cardinal_dist > MIN_DIST else cardinal_dist

		APPROACH:
			state_timer = 0.5
			state_counter = 0
			accel = 5
			play_animation('Walk')
			
		DISCOMBOBULATE:
			state_counter = int(2 + 3*randf())
			play_animation('Windup')
			state_timer = -1
			target_velocity = Vector2.ZERO
			accel = 3
			sprite.material.set_shader_param('color', Color.red)
			collision_layer = 0
			stagger_resists = phase
			
		TELEGRAPH_RAM:
			state_timer = 2 - 0.5*phase
			target_velocity = Vector2.ZERO
			accel = 8
			sprite.material.set_shader_param('color', Color.red)
			sight_raycast.enabled = true
			play_animation('Idle')
			
		RAM:
			state_health = 50
			target_velocity = to_player.normalized()*600
			accel = 3.5 + phase*0.5
			emit_ghost_trail = true
			ram_cooldown = 4
			grind_particles.rotation = Vector2(abs(target_velocity.x), target_velocity.y).angle()
			grind_particles.scale.x = abs(grind_particles.scale.x)*sign(target_velocity.x)
				
			grind_particles.emitting = true
			
		PUNCH:
			state_timer = 0.7
			play_animation('Punch')
			
		WAVE_DASH:
			state_timer = 0.25
			velocity = velocity.normalized()*700
			target_velocity = Vector2.ZERO
			accel = 6
			emit_ghost_trail = true

		CARDINAL_WAVE:
			accel = 8
			target_velocity = Vector2.ZERO
			aim_dir = 500*(Vector2(sign(to_player.x), 0) if (abs(to_player.x) > abs(to_player.y)) else Vector2(0, sign(to_player.y)))
			play_animation("Special")
			
		TELEGRAPH_PILLAR:
			state_timer = 5
			target_point = arena_center
			play_animation('Walk')
			
			
		PILLAR_WAVE:
			choose_random_pillar_pattern()
			state_counter = len(cur_pillar_pattern['enemies'])
			state_timer = 0.5
			target_velocity = Vector2.ZERO
			accel = 10
			pillar_cooldown = 10
			play_animation('Special')
			
		TELEGRAPH_VOLLEY:
			state_timer = 0.5
			target_velocity = Vector2.ZERO
			accel = 8
			eye_particles.emitting = true
			
		DIAGONAL_VOLLEY:
			state_timer = -1
			state_counter = 5
			aim_dir = Vector2(sign(to_player.x), sign(to_player.y))
			
		STAGGER:
			state_timer = 1.5 if swap_shield_health > 0 else 3
			target_velocity = Vector2.ZERO
			accel = 5
			play_animation('Idle')
			
		PLAYER:
			state_timer = 0
			accel = 5
			look_at_player = false

func process_state(delta, state):
	#breakpoint
	if not is_player and (not is_instance_valid(GameManager.player) or GameManager.player_hidden) and state != INACTIVE:
		set_state(INACTIVE)
		return
	
	match state:
		INACTIVE:
			if is_instance_valid(GameManager.player):
				state_timer = 0
				set_state(IDLE)
				
		IDLE:
			if health/max_health < super_move_thresholds[super_moves_used]:
				super_moves_used += 1
				set_state(APPROACH)
				
			elif (arena_enemy_count < 2 and pillar_count == 0) or pillar_cooldown < 0 and randf() > 0.3*pillar_count:
				set_state(TELEGRAPH_PILLAR)
				
			elif ram_cooldown < 0 and pillar_count > 0 and (arena_enemy_count < 1 or randf() < 0.2):
				set_state(TELEGRAPH_RAM)
				
			else:
				set_state(ALIGN)
				
		ALIGN:
			var very_close = dist_to_player < 30
			var dist_from_alignment
			var player_vel_from_alignment
			if abs(to_player.x) < abs(to_player.y):
				target_point = player_pos + Vector2(0, target_dist*sign(-to_player.y))
				dist_from_alignment = (global_position - target_point).x
				player_vel_from_alignment = GameManager.player.velocity.x * -sign(dist_from_alignment)
			else:
				target_point = player_pos + Vector2(target_dist*sign(-to_player.x), 0)
				dist_from_alignment = (global_position - target_point).y
				player_vel_from_alignment = GameManager.player.velocity.y * -sign(dist_from_alignment)
			
			move_toward_target()
			
			if state_timer < 0.4:
				if abs(dist_from_alignment) < 20:
						set_state(CARDINAL_WAVE)
				elif state_timer < 0:
					if abs(dist_from_alignment) < 50 and player_vel_from_alignment > 40:
						set_state(WAVE_DASH)
					elif dist_to_player > 50 and randf() > 0.5:
						set_state(TELEGRAPH_VOLLEY)
					else:
						set_state(IDLE)
				
		APPROACH:
			if state_counter == 0:
				var t = min(0.5 - state_timer, 0.5)
				sprite.position.y = -(t - 2*t*t) * (40*8)
				if state_timer < 0:
					state_counter = 1
					state_timer = 3.0
					GameManager.camera.set_trauma(0.5)
			elif state_timer < 2.5:
				target_point = player_pos
				move_toward_target(max_speed*1.5)
				
				if global_position.distance_to(target_point) < 60:
					set_state(DISCOMBOBULATE)
				elif state_timer < 0:
					set_state(IDLE)
				
		DISCOMBOBULATE:
			if state_timer < 0:
				if state_counter == 0:
					emit_ghost_trail = false
					set_state(PUNCH)
				elif state_counter > 1:
					state_timer = 0.6 - 0.15*phase
					target_point = player_pos + Vector2((120 + 30*randf())*sign(to_player.x), 80*randf() - 40)
				else:
					state_timer = 1.0
					target_point = player_pos + Vector2(100*sign(to_player.x), 0)
					target_dist = 50*sign(to_player.x)
				
				emit_ghost_trail = true
				var to_point = target_point - global_position
				var dist = max(to_point.length(), 1)
				velocity = to_point/dist * (700 + 3.3*(dist - 220)) #Empirically calculated!
				
				state_counter -= 1
				
			if state_counter == 0:
				target_point = player_pos + Vector2(target_dist, 0)
				move_toward_target()
				if state_timer < 0.66:
					sprite.material.set_shader_param('color', Color.red)
					sprite.material.set_shader_param('intensity', int(state_timer*20)%2*0.6)
					if event_happened('damaged_by_player'):
						if stagger_resists == 0:
							velocity -= to_player.normalized()*500
							swap_shield_health -= 2
							shield_flicker = true
							set_state(STAGGER)
						else:
							stagger_resists -= 1
							state_timer = 1.0
							state_counter = 1 + int(randf()*2)
							target_velocity = Vector2.ZERO
							velocity -= to_player.normalized()*400
			
		TELEGRAPH_RAM:
			sprite.material.set_shader_param('color', Color.red)
			sprite.material.set_shader_param('intensity', (0.5 + 0.5*sin(state_timer*(10 + 5*(3 - state_timer))))*0.6)
			
			sight_raycast.cast_to = (player_pos - global_position)/scale
			if sight_raycast.is_colliding() and (sight_raycast.get_collision_point() - player_pos).length() > 30:
				state_timer -= delta*5
				
			if state_timer < 0:
				set_state(RAM)
				
		RAM:
			var hit_pillar = false
			var collision_event = get_event('hitbox_collision')
			if collision_event:
				var entity = collision_event[1].get_parent()
				if entity.is_in_group('enemy pillar'):
					entity.call_deferred('die')
					hit_pillar = true
				else:
					entity.take_damage(100, self)
					entity.velocity += (entity.global_position - global_position).normalized()*1000
			
			var hit_wall = event_happened('body_collision')
					
			if hit_pillar or hit_wall:
				GameManager.spawn_explosion(global_position, self, 1.3, 50, 800, 0, true)
				var offset = Vector2(40, 0)
				for i in range(6):
					GameManager.spawn_explosion(global_position + offset, self, 0.7, 20, 500, 0.25, true)
					offset = offset.rotated(PI/3)
				offset = Vector2(60, 0)
				for i in range(20):
					GameManager.spawn_explosion(global_position + offset, self, 0.4, 10, 300, 0.5, true)
					offset = offset.rotated(PI/10)	
				
				if hit_pillar:
					GameManager.camera.set_trauma(0.6)
					velocity = -velocity
					swap_shield_health -= 1
					shield_flicker = true
				else:
					GameManager.camera.set_trauma(0.4)
					
				set_state(STAGGER)
			
		PUNCH:
			if event_happened('anim_trigger'):
				punch()
				
			if event_happened('anim_finished'):
				set_state(IDLE)
					
		WAVE_DASH:
			if state_timer < 0:
				if randf() < 0.9:
					set_state(CARDINAL_WAVE)
				else:
					set_state(TELEGRAPH_RAM)
					
		CARDINAL_WAVE:
			if event_happened('anim_trigger'):
				spawn_explosion_wave(aim_dir)
				
			if event_happened('anim_finished'):
				set_state(IDLE)
				
		TELEGRAPH_PILLAR:
			move_toward_target()
			if dist_to_target < 10:
				set_state(PILLAR_WAVE)
			elif state_timer < 0:
					set_state(IDLE)
				
		PILLAR_WAVE:
			var t = min(0.5 - state_timer, 0.5)
			sprite.position.y = -(t - 2*t*t) * (40*8)
			
			if event_happened('anim_trigger'):
				var i = len(cur_pillar_pattern['enemies']) - state_counter
				var point = arena_center + cur_pillar_pattern['offsets'][i]*arena_radius
				var delay = spawn_explosion_wave(point, 5)
				spawn_pillar_after_delay(cur_pillar_pattern['enemies'][i], point, delay)
					
			if event_happened('anim_finished'):
				if state_counter > 1:
					state_counter -= 1
					state_timer = 0.5
					play_animation('Special')
				else:
					set_state(IDLE)
			
		TELEGRAPH_VOLLEY:
			if state_timer < 0:
				set_state(DIAGONAL_VOLLEY)
				
		DIAGONAL_VOLLEY:
			if state_timer < 0:
				if state_counter > 0:
					state_timer = 0.125
					state_counter -= 1
					
					var i = 4 - state_counter
					var d = aim_dir.rotated(i*PI/25)
					for j in range(1 if i == 0 else 2):
						for k in range(5):
							var spd = 200 - 20*k
							var size = 2 - 0.25*k
							var damage = 20/(k+1)
							Violence.shoot_bullet(self, eye_pos, d*spd, damage, size*0.5, 5, 'pellet', 0, Vector2(size, size))
						d = aim_dir.rotated(-i*PI/25)
						
					
				else:
					set_state(IDLE)
					
		STAGGER:
			if state_timer < 1:
				sprite.offset.x += (randf() - 0.5)*4
			if state_timer < 0:
				set_state(IDLE)
				
		PLAYER:
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
			
			if state_timer < 0:
				aim_dir = get_global_mouse_position() - global_position
				update_look_direction(aim_dir)
				
				if velocity.length() > 20:
					play_animation('Walk')
				else:
					play_animation('Idle')
			
				if Input.is_action_just_pressed("attack1"):
					state_timer = 0.7
					play_animation('Attack')
					
				elif Input.is_action_just_pressed("attack2"):
					state_timer = 0.9
					play_animation('Special')
			else:
				var anim_event = get_event('anim_trigger')
				if anim_event:
					if anim_event[1] == 'Attack':
						punch()
						
					elif anim_event[1] == 'Special':
						var delay = spawn_explosion_wave(get_global_mouse_position() - global_position)
						spawn_pillar_after_delay(Enemy.EnemyType.UNKNOWN, get_global_mouse_position(), delay)
					
			
func exit_state(state):
	match state:
		DISCOMBOBULATE:
			collision_layer = 1024
			sprite.material.set_shader_param('intensity', 0)
			emit_ghost_trail = false
		WAVE_DASH:
			emit_ghost_trail = false
		TELEGRAPH_RAM:
			sprite.material.set_shader_param('intensity', 0)
			sight_raycast.enabled = false
		RAM:
			emit_ghost_trail = false
			grind_particles.emitting = false
		PILLAR_WAVE:
			sprite.position.y = 0
		DIAGONAL_VOLLEY:
			eye_particles.emitting = false
		STAGGER:
			shield_flicker = false
			#sprite.position.x = 0
			if swap_shield_health <= 0:
				swap_shield_health = 3
		PLAYER:
			look_at_player = true
				

func update_look_direction(dir):
	.update_look_direction(dir)
	punch_collider.position.x = -36 if facing_left else 36
			
func toggle_playerhood(is_player):
	.toggle_playerhood(is_player)
	GameManager.controlling_boss = is_player
	if is_player:
		set_state(PLAYER)
	else:
		set_state(STAGGER)
		
func punch():
	GameManager.camera.set_trauma(1.0 if is_in_group('player') else 0.6)
	GameManager.set_timescale(0.3)
	var hits = Violence.melee_attack(self, punch_collider, 300, 1500, 1)
	for hit in hits:
		if hit == GameManager.true_player:
			GameManager.set_timescale(0.1, 0.3)
		
			
func spawn_explosion_wave(vector, damage = 20, delta_delay = 0.07):
	if vector == Vector2.ZERO:
		return 0
		
	var dist = vector.length()
	var dir = vector/dist
	var start = foot_pos + dir*30
	var end = start + vector
	
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(start, end, [], 1)
	if result:
		end = result['position']
		
	dist = start.distance_to(end)
	var angle = dir.angle()
	var num_explosions = int(dist/25)
	var delta_x = dist/max(num_explosions - 1, 1)
	var max_y = 30.0
	
	var point = Vector2.ZERO
	var delay = 0
	var points = []
	
	for i in range(num_explosions):
		points.append(point)
		point.x += delta_x
		
		if i == num_explosions - 3:
			point.y = (randf() - 0.5)*0.3*max_y
		elif i == num_explosions - 2:
			point = end
		else:
			point.y += (2*randf() - 1 - point.y/max_y)*0.5*max_y
	
	for p in points:
		p = start + p.rotated(angle)
		GameManager.spawn_explosion(p, self, 0.5 + randf()*0.25, damage, 500, delay + randf()*0.03)
		delay += delta_delay
		
	GameManager.camera.set_trauma(0.7 if is_in_group('player') else 0.4)
	return delay
	
func spawn_pillar_after_delay(type, pos, delay):
	var pillar = EnemyPillar.instance().duplicate()
	pillar.enemy_type = type
	pillar.appear_timer = delay
	get_parent().add_child(pillar)
	pillar.global_position = pos
	pillar.connect('on_death', self, 'on_pillar_death')
	pillars.append(pillar)
	pillar_count += 1
	
func on_pillar_death(enemy):
	pillar_count -= 1
	Util.remove_invalid(pillars)
	arena_enemies.append(enemy)
	
func choose_random_pillar_pattern():
	var weights = []
	for i in range(len(pillar_patterns)):
		var p = pillar_patterns[i]
		var repeat = cur_pillar_pattern and len(p['offsets']) == len(cur_pillar_pattern['offsets'])
		if repeat:
			for j in range(len(p['offsets'])):
				if p['offsets'][j] != cur_pillar_pattern['offsets'][j]:
					repeat = false
					break
		weights.append(0 if repeat else p['weight'])
		
	cur_pillar_pattern = Util.choose_weighted(pillar_patterns, weights)
	
func die():
	if dead: return
	.die()
	
	Util.remove_invalid(arena_enemies)
	for enemy in arena_enemies:
		if enemy != GameManager.true_player:
			enemy.die()
			
	Util.remove_invalid(pillars)
	for pillar in pillars:
		if is_instance_valid(pillar.enemy):
			pillar.enemy.die()
	
	
		
