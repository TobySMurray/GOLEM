extends Area2D

var source
var velocity = Vector2.ZERO
var damage = 0

func _physics_process(delta):
	position += velocity*delta

func _on_Area2D_body_entered(body):
	if body != source:
		if body.is_class("Enemy"):
			body.take_damage(damage)
		queue_free()
