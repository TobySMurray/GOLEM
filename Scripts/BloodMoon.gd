extends AnimatedSprite

var selected_enemy
signal selected_enemy_signal

func _ready():
	print(self.get_parent().get_parent())
	self.connect("selected_enemy_signal", get_node("../../Transcender"), "toggle_selected_enemy")

func _on_Area2D_body_entered(body):
	if visible and body.is_in_group("enemy"):
		selected_enemy = body
		emit_signal("selected_enemy_signal", true)
		
func _on_Area2D_body_exited(body):
	if body.is_in_group("enemy"):
		selected_enemy = null
		emit_signal("selected_enemy_signal", false)
