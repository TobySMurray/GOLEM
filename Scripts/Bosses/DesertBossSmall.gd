extends Enemy

enum {FREE, SWARM, BLOB, SNAKE}
var behaviour = SWARM #for testing

var hivemind = null

var leader = null
var followers = []
var formation_size = 0

var sight_range = 10000
var avoidance_range = 1000

var cohesion = 0.2
var avoidance = 80
var alignment = 0.001
var leadership = 500
var min_speed = 50

var snake_next = null

func _ready():
	max_speed = 200
	max_health = 10
	init_healthbar()

func ai_move():
	match behaviour:
		FREE:
			pass;
			
		SWARM:
			if is_instance_valid(leader):
				var nearby = get_nearby()
				
				apply_leadership()
				if not nearby.empty():
					apply_cohesion(nearby)
					apply_avoidance(nearby)
					apply_alignment(nearby)
					
				limit_speed()

func apply_cohesion(nearby):
	var avg_pos = Vector2.ZERO
	for ad in nearby:
		avg_pos += ad.global_position    
	velocity += cohesion*(avg_pos/len(nearby) - global_position)
	
func apply_avoidance(nearby):
	for ad in nearby:
		var sqr_dist = global_position.distance_squared_to(ad.global_position) + 1
		if sqr_dist < avoidance_range:
			velocity -= avoidance*(ad.global_position - global_position)/sqr_dist
			
func apply_alignment(nearby):
	var avg_vel = Vector2.ZERO
	for ad in nearby:
		avg_vel += ad.velocity
	velocity += alignment*(avg_vel - velocity)
	
func apply_leadership():
	var dist_squared = global_position.distance_squared_to(leader.global_position) + 1
	velocity += leadership*(leader.global_position - global_position)/max(dist_squared, 300)        
	
func limit_speed():
	var speed = velocity.length()
	if speed > max_speed:
		velocity *= max_speed/speed    
	if speed < min_speed:
		velocity *= min_speed/speed
func get_nearby():
	var nearby = []
	for ad in leader.followers:
		if global_position.distance_squared_to(ad.global_position) < sight_range:
			nearby.append(ad) 
	nearby.append(leader)   
	return nearby
	
func add_to_formation(ad):
	if leader != self:
		return
	
	ad.leader = self
	ad.behaviour = behaviour
	
	if behaviour == SNAKE:
		var displaced = followers[int(randf()*len(followers))]
		ad.snake_next = displaced.snake_next
		displaced.snake_next = ad
		
	followers.append(ad)
	formation_size += 1
	
func get_random_nearby_formation():
	var weights = []
	for leader in hivemind.leaders:
		weights.append(1.0/global_position.distance_to(leader.global_position))
	return Util.choose_weighted(hivemind.leaders, weights)

func die(killer = null):
	if leader:
		leader.on_follower_death(self)
	.die(killer)
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Spawn":
		attacking = false
	elif anim_name == "Die":
		actually_die()
