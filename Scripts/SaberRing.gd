extends KinematicBody2D

const zaps = [
	preload('res://Sounds/SoundEffects/Saber1.wav'),
	preload('res://Sounds/SoundEffects/Saber2.wav'),
	preload('res://Sounds/SoundEffects/Saber3.wav')
]

onready var audio_players = [
	$Audio1,
	$Audio2,
	$Audio3
]

var source

var velocity = Vector2.ZERO
var max_accel = 300
var accel = max_accel
var max_speed = 5000
var damage = 5
var kb_speed = 1000
var mass = 0.1
var deflect_level = 1

var target_pos = Vector2.ZERO

var being_recalled = false
var recalled = false
var recall_timer = 0
var recall_offset = Vector2.ZERO

var invincible = false
var lifetime = 0

var next_audio_player = 0

func _ready():
	accel = max_accel

func recall():
	being_recalled = true
	recalled = false
	recall_timer = 0.3

func _physics_process(delta):
	if not is_instance_valid(source):
		queue_free()
	
	if not being_recalled:
		velocity = move_and_slide(velocity)
		
		modulate = Color.white.linear_interpolate(Color(1, 0, 0.45), float(accel)/max_accel)
		if accel < max_accel:
			accel += 0.5
			
		var to_target = target_pos - global_position
		var target_dist = to_target.length()
		
		velocity += accel*(to_target/target_dist)*clamp(target_dist-5, 0, 20)*delta
		if target_dist < 10:
			velocity *= 0.9
		
		var speed = max(velocity.length(), 1)
		velocity -= velocity/speed*min(speed*speed*0.0005, speed)
	
	else:
		recall_timer -= delta
		global_position = lerp(global_position, target_pos, 0.2)
		recalled = (target_pos - global_position).length() < 7 or recall_timer < 0

func _on_Area2D_area_entered(area):
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible and entity != source and not (entity.is_in_group('saber ring') and entity.source == source):
			entity.take_damage(damage, source)
			play_zap()
			
			var kb_vel= (entity.global_position - global_position).normalized() * kb_speed
			if area.is_in_group("death orb"):
				kb_vel /= 3
			
			entity.velocity += kb_vel
			velocity -= kb_vel
			accel -= 5/mass
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (-kb_vel).angle(), 600, 5, 30)
	
	elif area.is_in_group("bullet") and area.source != source:
		play_zap()
		if deflect_level == 1:
			area.velocity = area.velocity.length()*(area.global_position - global_position).normalized()
		else:
			if is_instance_valid(area.source):
				area.velocity = area.velocity.length()*(deflect_level-1)*(area.source.global_position - area.global_position).normalized()
			else:
				area.velocity *= -(deflect_level-1)
		area.source = source
		area.lifetime = 2
		
func on_laser_deflection(impact_point, dir, width, beam_source, beam_damage, kb, stun, piercing, style, explosion_size, explosion_damage, explosion_kb):
	take_damage(-beam_damage*0.8, beam_source)
	play_zap()
	
	var normal = (impact_point - global_position).angle()
	var reflection_angle
	if deflect_level == 1 or not is_instance_valid(source):
		reflection_angle = Util.signed_wrap(normal - ((-dir).angle() - normal))
	else:
		reflection_angle = (beam_source.global_position - impact_point).angle()
	
	var beam_dir = Vector2(cos(reflection_angle), sin(reflection_angle))
	LaserBeam.shoot_laser(impact_point, beam_dir, width, source, beam_damage, kb, stun, piercing, style, explosion_size, explosion_damage, explosion_kb, true)
	return true
	
func play_zap():
	var player = audio_players[next_audio_player]
	player.stream = zaps[int(randf()*len(zaps))]
	player.pitch_scale = 0.95 + randf()*0.1
	player.play()
	next_audio_player = (next_audio_player + 1)%len(audio_players)
	
func take_damage(damage, source, stun = 0):
	accel -= damage/(mass*3)
	pass
