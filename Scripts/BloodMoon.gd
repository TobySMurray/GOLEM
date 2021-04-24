extends AnimatedSprite





func _on_Area2D_body_entered(body):
	if body.is_in_group("enemy"):
		if Input.is_action_pressed("select"):
			swap()
