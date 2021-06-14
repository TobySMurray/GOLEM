extends Area2D

var source
var velocity = Vector2.ZERO
var lifetime = 10
var damage = 0
var mass = 0.25

func _physics_process(delta):
	lifetime -= delta
	if lifetime < 0:
		despawn()
	position += velocity*delta

func _on_Area2D_body_entered(body):
	if not (body.is_in_group("player") or body.is_in_group("enemy")):
		despawn()


func _on_Area2D_area_entered(area):
	if area.is_in_group("hitbox"):
		var entity = area.get_parent()
		if not entity.invincible and entity != source:
			entity.take_damage(damage, source)
			entity.velocity += velocity*mass/entity.mass
			
			if not entity.is_in_group("bloodless"):
				GameManager.spawn_blood(entity.global_position, (velocity).angle(), sqrt(velocity.length())*30, damage, 30)
			
			if not area.is_in_group("deflector"):
				despawn()
			
func despawn():
	GameManager.player_bullets.erase(self)
	queue_free()
