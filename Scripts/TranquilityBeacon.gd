extends Area2D

onready var sprite = $Sprite
onready var label = $Label

var active = false
export var tranquil_mode = true

func _ready():
	toggle_tranquil_mode(tranquil_mode)

func _physics_process(delta):
	if tranquil_mode:
		GameManager.player_hidden = true
	
func _input(ev):
	if active and ev is InputEventKey and ev.pressed and ev.scancode == KEY_E and not ev.echo:
		toggle_tranquil_mode(not tranquil_mode)
		
	if ev is InputEventKey and ev.pressed and ev.scancode == KEY_T and not ev.echo:
		toggle_tranquil_mode(not tranquil_mode)
		
	if ev is InputEventKey and ev.pressed and ev.scancode == KEY_R and not ev.echo:
		GameManager.swap_bar.enabled = (not GameManager.swap_bar.enabled)
		
func toggle_tranquil_mode(state):
	if not state:
		print('Retaliation enabled')
		tranquil_mode = false
		sprite.material.set_shader_param('color', Color.red)
		label.text = ':('
		GameManager.reveal_player()
	else:
		print('Retaliation disabled')
		tranquil_mode = true
		sprite.material.set_shader_param('color', Color.green)
		label.text = ':)'
			
func _on_TranquilityBeacon_body_entered(body):
	if body.is_in_group('host') and body.is_in_group('player'):
		active = true
	
func _on_TranquilityBeacon_body_exited(body):
	if body.is_in_group('host') and body.is_in_group('player'):
		active = false
