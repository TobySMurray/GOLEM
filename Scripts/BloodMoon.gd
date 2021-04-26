extends AnimatedSprite

var selected_enemy
signal selected_enemy_signal
onready var stopped = $Stopped
var moon_visible = false

func _ready():
	print(self.get_parent().get_parent())
	self.connect("selected_enemy_signal", GameManager.transcender, "toggle_selected_enemy")

func _physics_process(delta):
	if moon_visible:
		modulate = lerp(modulate, Color(1,1,1,1), 0.1)
	if !moon_visible:
		modulate = lerp(modulate, Color(1,1,1,0), 0.2)

func _on_Area2D_body_entered(body):
	if moon_visible and body.is_in_group("enemy") and body.swap_shield_health <= 0 and body.health > 0:
		selected_enemy = body
		emit_selected_enemy_signal(true)
		
func _on_Area2D_body_exited(body):
	if moon_visible and body.is_in_group("enemy") and body.swap_shield_health <= 0 and body.health > 0:
		selected_enemy = null
		emit_selected_enemy_signal(false)

func emit_selected_enemy_signal(state):
	if moon_visible:
		self.modulate.a = 1 if state else 0.3
		emit_signal("selected_enemy_signal", state)

func _on_Slow_finished():
	stopped.play()


func _on_Speed_finished():
	stopped.stop()
