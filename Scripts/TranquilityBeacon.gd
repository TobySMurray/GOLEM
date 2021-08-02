extends Area2D

onready var sprite = $Sprite
onready var label = $Label

var active = false
var tranquil_mode = true

func _physics_process(delta):
	if tranquil_mode:
		GameManager.player_hidden = true
	
func _input(ev):
	if active and ev is InputEventKey and ev.pressed and ev.scancode == KEY_E and not ev.echo:
		if tranquil_mode:
			print('Retaliation enabled')
			tranquil_mode = false
			sprite.material.set_shader_param('color', Color.red)
			label.text = ':('
			GameManager.player_hidden = false
		else:
			print('Retaliation disabled')
			tranquil_mode = true
			sprite.material.set_shader_param('color', Color.green)
			label.text = ':)'
			
func _on_TranquilityBeacon_body_entered(body):
	if body.is_in_group('player'):
		active = true
	
func _on_TranquilityBeacon_body_exited(body):
	if body.is_in_group('player'):
		active = false
