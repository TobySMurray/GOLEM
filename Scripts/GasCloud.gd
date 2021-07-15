extends KinematicBody2D

var source = null

var velocity = Vector2.ZERO
var decel = Vector2.ZERO

var next_in_chain = []
var detonating = false
var timer = 0.1

func set_vel(vel):
	velocity = vel
	decel = -vel/2

func _physics_process(delta):
	var col = move_and_collide(velocity*delta)
	
	if col:
		velocity = velocity.bounce(col.normal) * 0.5
		decel = decel.bounce(col.normal)
	
	if velocity.length_squared() > 400:
		velocity += decel*delta
	else:
		velocity *= 0.95
		
	if detonating:
		timer -= delta
		if timer < 0:
			for cloud in next_in_chain:
				cloud.detonate()
			GameManager.spawn_explosion(global_position, source, 0.4 + randf()*0.3, 25, 200)
			queue_free()

func detonate(delay = 0.07):
	detonating = true
	timer = delay
