extends Line2D

onready var hook = $HookCollider
signal entity_hooked

var source = null

var launched = false
var maxed = false
var anchored = false

var endpoint = Vector2.ZERO
var endpoint_vel = Vector2.ZERO
var startpoint = Vector2.ZERO
var anchor_entity = null

var anchored_length = 0
var anchored_slack = 0.5
var retract_force = 20

var retract_timer = 0

var segment_count = 0
var segments = []

var segment_length = 7
var tension = 100
var drag = 0.1

func _ready():
	clear_points()
	launch(Vector2(1, 1)*300)
	
func _physics_process(delta):
	#segments[0][0] = get_global_mouse_position() - position
	if launched:
		endpoint += endpoint_vel*delta
		segments[0][0] = endpoint
		if segment_count < 40:
			if segments[segment_count-1][0].distance_to(startpoint) > segment_length:
				startpoint = Vector2(randf(), randf())*10
				add_point(startpoint)
				segments.append([startpoint, startpoint])
				segment_count += 1
		else:
			launched = false
			maxed = true

	if maxed or anchor_entity:
		segments[segment_count-1][0] = startpoint
		
	if anchor_entity:
		pass
		endpoint = anchor_entity.global_position - global_position
		segments[0][0] = endpoint

		anchored_length = max(0, anchored_length - delta*300.0)
		var anchor_dist = endpoint.length()
		if anchor_dist < anchored_length:
			anchored_length = 0.9*anchored_length + 0.1*anchor_dist
		else:
			var error_dist = anchor_dist - anchored_length
			var force = -endpoint.normalized()*error_dist*retract_force*delta
			var mass_ratio = 1 #temp
			anchor_entity.velocity += force*mass_ratio
			#source.velocity -= force*(1 - mass_ratio)
		
		segment_length = (anchored_length/segment_count)*anchored_slack

		
	if segment_count > 1:
		simulate(delta)
		
	hook.position = segments[0][0]
	
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
		set_point_position(i, cur_pos)
		
	for i in range(20):
		apply_constraints()
	
func apply_constraints():
#	var p1 = segments[0][0]
#	var p2 = segments[1][0]
#	var dist = p1.distance_to(p2)
#	var error = dist - segment_length
#	var correction = error*(p2 - p1)/dist
#
#	segments[1][0] = p2 - correction
	
	for i in range(0, segment_count-1):
		var p1 = segments[i][0]
		var p2 = segments[i+1][0]
		var dist = p1.distance_to(p2)
		var error = dist - segment_length
		var correction = 0.5*error*(p2 - p1)/dist
		
		segments[i][0] = p1 + correction
		segments[i+1][0] = p2 - correction
		
func launch(vel):
	clear_points()
	add_point(Vector2.ZERO)
	add_point(Vector2.ZERO)
	segments.append([Vector2.ZERO, Vector2.ZERO])
	segments.append([Vector2.ZERO, Vector2.ZERO])
	segment_count = 2
	endpoint = Vector2.ZERO
	endpoint_vel = vel
	launched = true


func _on_HookCollider_area_entered(area):
	if area.is_in_group('hitbox'):
		var entity = area.get_parent()
		if entity != source and entity.is_in_group('enemylike'):
			anchor_entity = entity
			anchored = true
			anchored_length = global_position.distance_to(entity.global_position)*0.9
			#entity.velocity += (global_position - entity.global_position)
			retract_timer = 1.2
			entity.override_accel = 2
			emit_signal('entity_hooked', entity)
