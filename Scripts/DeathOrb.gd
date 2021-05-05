extends KinematicBody2D

var source
var velocity = Vector2(100, 0)
var mass = 3

var lifetime = 0
var invincible = false

func _physics_process(delta):
	var col = move_and_collide(velocity*delta)
	if col:
		velocity = velocity.bounce(col.normal) * 0.9


func _on_Area2D_area_entered(area):
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible and entity != source:
			entity.take_damage(pow(velocity.length(), 1.5)/100, source)
			var new_vel = (global_position - entity.global_position).normalized() * velocity.length()
			var delta_vel = new_vel - velocity
			velocity = new_vel * 1.05
			entity.velocity -= delta_vel*2
			
func take_damage(damage, source):
	pass
	
			
