extends KinematicBody2D

class_name Boss

const GhostImage = preload('res://Scenes/GhostImage.tscn')
onready var sprite = $Sprite
onready var animplayer = $AnimationPlayer
onready var healthbar = $HealthBar

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

# ENEMY-LIKE VARS
export var max_health = 100
onready var health = float(max_health)
export var mass = 1.0
export var max_speed = 100
export var accel = 10.0
export var stun_resist = 0.0

var enemy_type = Enemy.EnemyType.UNKNOWN

var velocity = Vector2.ZERO

var stunned = false
var stun_timer = 0

var swap_shield_health = 2
var time_since_controlled = 999

var max_attack_cooldown = 0.0
var max_special_cooldown = 0.0

var dead = false
var invincible = false
var damage_flash = false
var damage_flash_timer = 0

var flip_offset = 0

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

var target_velocity = Vector2.ZERO

var look_at_player = true

# MISC
var emit_ghost_trail = false
var ghost_trail_interval = 0.1
var ghost_trail_timer = -1


func _physics_process(delta):
	if dead:
		return
		
	state_timer -= delta
	if GameManager.player:
		player_pos = GameManager.player.global_position
		to_player = player_pos - global_position
		dist_to_player = player_pos.length()
		to_target = target_point - global_position
		dist_to_target = global_position.distance_to(target_point)
		
	if damage_flash:
		damage_flash_timer -= delta
		if damage_flash_timer < 0:
			damage_flash = 0
			sprite.material.set_shader_param('intensity', 0)
			
	update_sprite_flip()
	
	process_state(delta, current_state)
	
	if interrupt:
		interrupt = false
		set_state(interrupt_state)
		
	frame_events.clear()
	move(delta)
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
	
func die():
	pass
	
func toggle_playerhood(state):
	GameManager.on_swap(self)
	
func toggle_enhancement(state):
	pass
	
func play_animation(anim):
	animplayer.play(anim)
	
func move_toward_target():
	target_velocity = max_speed*global_position.direction_to(target_point)
	
func update_sprite_flip(look_dir = null):
	if not look_dir:
		look_dir = to_player.x if look_at_player else target_velocity.x
	if look_dir > 0:
		sprite.flip_h = false
		sprite.offset.x = 0
	else:
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
			
func on_bullet_despawn(bullet):
	pass
			
func on_anim_trigger_frame():
	#breakpoint
	frame_events.append(['anim_trigger', animplayer.current_animation])
		
func _on_AnimationPlayer_animation_finished(anim):
	if anim == 'Die':
		queue_free()
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

