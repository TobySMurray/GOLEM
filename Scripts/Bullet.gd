extends Area2D

var source
var velocity = Vector2.ZERO
var lifetime = 10
var damage = 0
var mass = 0.25

func _physics_process(delta):
	lifetime -= delta
	if lifetime < 0:
		queue_free()
	position += velocity*delta

func _on_Area2D_body_entered(body):
	queue_free();


func _on_Area2D_area_entered(area):
	if (area.is_in_group("hitbox")):
		var entity = area.get_parent()
		if not entity.invincible and entity != source:
			entity.take_damage(damage)
			entity.velocity += velocity*mass
		queue_free()
