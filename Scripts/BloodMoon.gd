extends AnimatedSprite

var selected_enemy

func _on_Area2D_body_entered(body):
	if body.is_in_group("enemy"):
		selected_enemy = body
		
func _on_Area2D_body_exit(body):
	if body.is_in_group("enemy"):
		selected_enemy = null
