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
	if body != source:
		if (body.is_in_group("enemy") or body.is_in_group("player")) and not body.invincible:
			body.take_damage(damage)
			body.velocity += velocity*mass
		queue_free()
