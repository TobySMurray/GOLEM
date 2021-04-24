extends AnimatedSprite

var selected_enemy

func _on_Area2D_body_entered(body):
	if visible and body.is_in_group("enemy"):
		selected_enemy = body
		
func _on_Area2D_body_exited(body):
	if body.is_in_group("enemy"):
		selected_enemy = null
