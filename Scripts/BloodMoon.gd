extends AnimatedSprite

var selected_enemy
signal selected_enemy_signal

func _ready():
	print(self.get_parent().get_parent())
	self.connect("selected_enemy_signal", GameManager.transcender, "toggle_selected_enemy")

func _on_Area2D_body_entered(body):
	if visible and body.is_in_group("enemy") and body.swap_shield_health <= 0:
		selected_enemy = body
		emit_selected_enemy_signal(true)
		
func _on_Area2D_body_exited(body):
	if body.is_in_group("enemy") and body.swap_shield_health <= 0:
		selected_enemy = null
		emit_selected_enemy_signal(false)

func emit_selected_enemy_signal(state):
	self.modulate.a = 1 if state else 0.3
	emit_signal("selected_enemy_signal", state)
