extends Line2D

onready var hook = $HookCollider
signal entity_hooked

onready var source = get_parent()

enum {
	INACTIVE,
	LAUNCHED,
	ANCHORED,
	RETRACTING,
}
var state = INACTIVE

var endpoint = Vector2.ZERO
var endpoint_vel = Vector2.ZERO
var startpoint = Vector2.ZERO
var anchor_entity = null

var anchored_length = 0
var anchored_slack = 0.5
var retract_force = 20

var hook_enabled = false
var hook_disable_timer = 0.0

var retract_timer = 0.0
var tugged = false
var prev_tugged = false

var max_segment_count = 30
var segment_count = 0
var segments = []

var init_segment_length = 7
var segment_length = init_segment_length
var tension = 100
var drag = 0.1

func _ready():
	deactivate()
	scale = Vector2.ONE/source.scale
	
func _physics_process(delta):
	if state != INACTIVE and segment_count > 0:
		hook.global_position = segments[0][0]
		
	if segment_count > 1:
		simulate(delta)
		
	match state:
		LAUNCHED:
			endpoint += endpoint_vel*delta
			segments[0][0] = endpoint
			if segment_count < max_segment_count:
				startpoint = endpoint_vel.tangent().normalized()*5*(sin(segment_count/1.5))
				while true:
					var dist = segments[segment_count-1][0].distance_to(startpoint + global_position)
					if dist > segment_length:
						var point = segments[segment_count-1][0] + segments[segment_count-1][0].direction_to(startpoint + global_position)*min(dist, segment_length)
						add_point(point - global_position)
						segments.append([point, point - endpoint_vel*delta])
						segment_count += 1
					else:
						break
			else:
				retract(true)
				
		RETRACTING:
			segments[segment_count-1][0] = global_position
			
			retract_timer -= delta
			if retract_timer < 0:
				retract_timer = 0.03
				segment_count -= 1
				remove_point(segment_count - 1)
				segments.remove(segment_count - 1)
				
				if segment_count < 2:
					deactivate()
					return
				
			if hook.collision_mask != 0:	
				hook_disable_timer -= delta
				if hook_disable_timer < 0:
					hook.collision_mask = 0
				
#			else:
#				closest_segment -= ((closest_segment - global_position)/dist)*min(250*delta, dist) 
#				segments[segment_count-1][0] = closest_segment
			
		ANCHORED:
			segments[segment_count-1][0] = global_position
			
			if is_instance_valid(anchor_entity) and not anchor_entity.dead:
				endpoint = anchor_entity.global_position
				var anchor_dist = endpoint.distance_to(global_position)
				segments[0][0] = endpoint

				if tugged or anchor_dist > init_segment_length * max_segment_count:
					anchor_entity.override_accel = 1.5
					anchored_length = 0
					if anchor_dist < anchored_length:
						anchored_length = 0.9*anchored_length + 0.1*anchor_dist
					else:
						var error_dist = anchor_dist - anchored_length
						var force = -(endpoint - global_position)/anchor_dist*error_dist*retract_force*delta
						
						var effective_mass
						if anchor_entity.is_in_group('enemy') and anchor_entity.immobile:
							effective_mass = 0.0
							source.override_accel = 1.5
						elif source.mass*1.5 > anchor_entity.mass or source.steady_body:
							effective_mass = source.mass*(4 if source.steady_body else 2)
						else:
							effective_mass = source.mass*0.5
							source.override_accel = 1.5
							
						var mass_ratio = effective_mass/(effective_mass + anchor_entity.mass)
						anchor_entity.velocity += force*mass_ratio
						source.velocity -= force*(1 - mass_ratio)
					
				else:
					if prev_tugged:
						anchor_entity.override_accel = 0.5
					elif anchor_entity.override_accel:
						anchor_entity.override_accel = 0.98*anchor_entity.override_accel + 0.02*anchor_entity.accel
					source.override_accel = null
					anchored_length = 0.9*anchored_length + 0.1*anchor_dist
					
				prev_tugged = tugged
				segment_length = (anchored_length/segment_count)*anchored_slack
				
			else:
				source.override_accel = null
				retract(false)
	
func simulate(delta):
	#segments[0][0] = get_global_mouse_position()
	for i in range(segment_count):
		var cur_pos = segments[i][0]
		var old_pos = segments[i][1]
		
		var velocity = cur_pos - old_pos
		old_pos = cur_pos
		cur_pos += velocity
		
		segments[i][0] = cur_pos
		segments[i][1] = old_pos
		set_point_position(i, cur_pos - global_position)
		
	for i in range(30):
		apply_constraints()
	
func apply_constraints():
#	var p1 = segments[0][0]
#	var p2 = segments[1][0]
#	var dist = p1.distance_to(p2)
#	var error = dist - segment_length
#	if dist > 0:
#		var correction = error*(p2 - p1)/dist*0.9
#		segments[1][0] = p2 - correction
	
	for i in range(0, segment_count-1):
		var p1 = segments[i][0]
		var p2 = segments[i+1][0]
		var dist = p1.distance_to(p2)
		var error = dist - segment_length
		if dist > 0:
			var correction = 0.5*error*(p2 - p1)/dist
			segments[i][0] = p1 + correction
			segments[i+1][0] = p2 - correction
		
func deactivate():
	clear_points()
	segments.clear()
	segment_count = 0
	hook.collision_mask = 0
	state = INACTIVE
	
		
func launch(vel):
	if state == INACTIVE:
		clear_points()
		add_point(Vector2.ZERO)
		add_point(Vector2.ZERO)
		segments = [[global_position, global_position], [global_position, global_position]]
		segment_count = 2
		endpoint = global_position
		endpoint_vel = vel
		segment_length = init_segment_length
		hook.collision_mask = 5
		hook.scale = Vector2.ONE
		state = LAUNCHED
	
func retract(enable_hook = true):
	if state == LAUNCHED or state == ANCHORED:
		if is_instance_valid(anchor_entity):
			anchor_entity.override_accel = null
			anchor_entity = null
			
		hook_disable_timer = 0.5 if enable_hook else 0
		state = RETRACTING
		
func anchor_to(entity):
	anchor_entity = entity
	anchored_length = global_position.distance_to(entity.global_position)*0.9
	#entity.velocity += (global_position - entity.global_position)
	#retract_timer = 1.2
	hook.collision_mask = 4
	if anchor_entity.is_in_group('enemy'):
		if anchor_entity.enemy_type in [Enemy.EnemyType.SHOTGUN, Enemy.EnemyType.CHAIN, Enemy.EnemyType.WHEEL, Enemy.EnemyType.FLAME]:
			hook.scale = Vector2.ONE*1.25
		else:
			hook.scale = Vector2.ONE*1.75
	elif anchor_entity.is_in_group('boss'):
		hook.scale = Vector2.ONE*3
	emit_signal('entity_hooked', entity)
	state = ANCHORED

func _on_HookCollider_area_entered(area):
	if area.is_in_group('hitbox'):
		var entity = area.get_parent()
		if entity != source and entity.is_in_group('enemylike') and not entity.dead:
			if state == LAUNCHED or state == RETRACTING:
				anchor_to(entity)
					
			elif state == ANCHORED and is_instance_valid(anchor_entity):
				var v1 = anchor_entity.velocity
				var v2 = entity.velocity
				var m1 = anchor_entity.mass
				var m2 = entity.mass
				var collision_speed = (anchor_entity.velocity - entity.velocity.project(anchor_entity.velocity)).length()
				
				if collision_speed > 150:
					var damage = collision_speed*0.15*anchor_entity.mass
					entity.take_damage(damage, source, source.grapple_stun)
					anchor_entity.take_damage(damage*0.25, source, 0)
					GameManager.spawn_blood(entity.position, anchor_entity.velocity.angle(), collision_speed, damage)
		
					anchor_entity.velocity = (m1 - m2)/(m1 + m2)*v1 + 2*m2/(m1 + m2)*v2
					entity.velocity = (m2 - m1)/(m1 + m2)*v2 + 2*m1/(m1 + m2)*v1


func _on_HookCollider_body_entered(body):
	if state == LAUNCHED:
		retract(true)
