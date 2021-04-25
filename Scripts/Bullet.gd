extends Area2D

var source
var velocity = Vector2.ZERO
var lifetime = 10
var damage = 0

func _physics_process(delta):
	lifetime -= delta
	if lifetime < 0:
		queue_free()
	position += velocity*delta

func _on_Area2D_body_entered(body):
	if body != source:
		if body.is_class("Enemy"):
			print("hit")
			body.take_damage(damage)
		queue_free()
