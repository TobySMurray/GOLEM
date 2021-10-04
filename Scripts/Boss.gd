extends Enemylike

class_name Boss

const LevelLoadTrigger = preload('res://Scenes/LevelLoadTrigger.tscn')
const GhostImage = preload('res://Scenes/GhostImage.tscn')
onready var healthbar = $EnemyFX/HealthBar

# STATE MACHINE VARS
var current_state = 0
var last_state = 0
var interrupt_state = 0

var interrupt = false

var state_timer = 0
var state_counter = 0
var state_health = 0

var last_state_timer = 0
var last_state_counter = 0
var last_state_health = 0

# AI VARS
var frame_events = []

var phase = 0
export var phase_thresholds = [0.0]

var player_pos = Vector2.ZERO
var to_player = Vector2.ZERO
var dist_to_player = 0
var target_point = Vector2.ZERO
var to_target = Vector2.ZERO
var dist_to_target = 0

var look_at_player = true
var look_direction = Vector2.ZERO

var arena_center = Vector2.ZERO


# MISC
var shield_flicker = false
var flicker_state = 0

var emit_ghost_trail = false
var ghost_trail_interval = 0.1
var ghost_trail_timer = -1

func _ready():
	GameManager.connect('on_level_ready', self, 'on_level_ready')

func on_level_ready():
	arena_center = global_position

func _physics_process(delta):
	if dead:
		return
		
	state_timer -= delta
	if is_instance_valid(GameManager.player):
		player_pos = GameManager.player.global_position
		to_player = player_pos - global_position
		dist_to_player = player_pos.length()
		to_target = target_point - global_position
		dist_to_target = global_position.distance_to(target_point)
		
		if look_at_player:
			update_look_direction(to_player)
		
	if damage_flash:
		damage_flash_timer -= delta
		if damage_flash_timer < 0:
			damage_flash = 0
			sprite.material.set_shader_param('intensity', 0)
			
	if interrupt:
		interrupt = false
		set_state(interrupt_state)
		
	if not stunned:
		process_state(delta, current_state)
		frame_events.clear()
	else:
		stun_timer -= delta
		if stun_timer < 0:
			stunned = false
	
	move(delta)
	update_shield_flicker()
	if emit_ghost_trail:
		update_ghost_trail(delta)
	
func set_state(state, reverted = false):
	if not reverted:
		last_state_timer = state_timer
		last_state_counter = state_counter
		last_state_health = state_health
	
	last_state = current_state
	current_state = state
	exit_state(last_state)
	enter_state(current_state)
	
func revert_state(restart = false):
	set_state(last_state, true)
	if not restart:
		state_timer = last_state_timer
		state_counter = last_state_counter
		state_health = last_state_health
		
func interrupt_state(new_state):
	interrupt_state = new_state
	interrupt = true
	
func enter_state(state):
	pass
	
func exit_state(state):
	pass
	
func process_state(delta, state):
	pass
	
func enter_phase(new_phase):
	pass
	
func move(delta):
	velocity = lerp(velocity, target_velocity, accel*delta)	
	
	var col = move_and_collide(velocity*delta, true, true, true)
	if col and (col.collider.collision_layer & 1 or (col.collider.collision_layer >> 10) & 1):
		frame_events.append(['body_collision', col])
	
	velocity = move_and_slide(velocity)
	
func move_toward_target(speed = max_speed):
	target_velocity = speed*global_position.direction_to(target_point)
	
func update_look_direction(look_dir):
	if look_dir.x > 0:
		facing_left = false
		sprite.flip_h = false
		sprite.offset.x = 0
	else:
		facing_left = true
		sprite.flip_h = true
		sprite.offset.x = flip_offset
		
func update_ghost_trail(delta):
	ghost_trail_timer -= delta
	if ghost_trail_timer < 0:
		ghost_trail_timer = ghost_trail_interval
		var new_ghost = GhostImage.instance().duplicate()
		get_parent().add_child(new_ghost)
		new_ghost.copy_sprite(sprite)
		new_ghost.set_lifetime(0.4)
		
func update_shield_flicker():
	if not swap_shield:
		return
		
	if shield_flicker:
		var r = randf()
		if flicker_state == 0:
			swap_shield.visible = false
			if r < 0.1:
				flicker_state = 1 if r < 0.05 else 2
		else:
			swap_shield.visible = true
			var apparent_health
			if flicker_state == 1:
				apparent_health = min(swap_shield_health/3.0, 1)
				if r < 0.5:
					flicker_state = 0 if r < 0.01 else 2 
			else:
				apparent_health = min((swap_shield_health + 1)/3.0, 1)
				if r < 0.1:
					flicker_state = 0 if r < 0.02 else 1 
			swap_shield.modulate = Color(0.5+apparent_health*0.5, apparent_health, apparent_health, 1)
			
	elif GameManager.swapping:
		swap_shield.visible = true
		var apparent_health = swap_shield_health / 3.0
		swap_shield.modulate = Color(0.5+apparent_health*0.5, apparent_health, apparent_health, 1)
		
	else:
		swap_shield.visible = false
		
	
func take_damage(damage, source, stun = 0):
	health -= damage
	state_health -= damage
	healthbar.value = health
	
	stun -= stun_resist*(0.5 + 0.5*randf())
	if stun > 0:
		stunned = true
		stun_timer = max(stun_timer, stun)
		
	if damage > 0:
		frame_events.append(['damaged', damage])
		if source == GameManager.true_player:
			frame_events.append(['damaged_by_player', damage])
			GameManager.swap_bar.set_swap_threshold(GameManager.swap_bar.swap_threshold - damage/50.0)
#			if GameManager.swap_bar.control_timer > GameManager.swap_bar.swap_threshold:
#				GameManager.swap_bar.control_timer = max(0, - GameManager.swap_bar.control_timer - damage/50.0)
		
		damage_flash = true
		damage_flash_timer = 0.05
		sprite.material.set_shader_param('color', Color.white)
		sprite.material.set_shader_param('intensity', 1)
		
		if health <= 0:
			die()
		elif phase < len(phase_thresholds) and health/max_health < phase_thresholds[phase]:
			phase += 1
			enter_phase(phase)
			
func init_healthbar():
	healthbar.max_value = max_health
	healthbar.value = health
	#healthbar.rect_scale.x = health / 200.0
	#healthbar.rect_scale.x = health / 200.0
			
func on_anim_trigger_frame():
	#breakpoint
	frame_events.append(['anim_trigger', animplayer.current_animation])
		
func _on_AnimationPlayer_animation_finished(anim):
	if anim == 'Die':
		var corpse = LevelLoadTrigger.instance()
		get_parent().add_child(corpse)
		corpse.global_position = global_position
		corpse.destination = 'WarpRoom'
		corpse.fixed_map = 'res://Scenes/Levels/WarpRoom.tscn'
		.actually_die()
	else:
		frame_events.append(['anim_finished', anim])
	
func on_hitbox_collision(area):
	if area.is_in_group('hitbox'):
		frame_events.append(['hitbox_collision', area])
	
func event_happened(event_name):
	for event in frame_events:
		if event[0] == event_name:
			return true
			
	return false
	
func get_event(event_name):
	for event in frame_events:
		if event[0] == event_name:
			return event
			
	return null

