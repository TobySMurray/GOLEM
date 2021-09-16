extends Area2D

onready var sprite = $Sprite
onready var number = $Number

var active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	number.set_digit(GameManager.evolution_level)
	
func _input(ev):
	if ev is InputEventKey:
		match(ev.scancode):
			KEY_0:
				set_evolution_level(0)
			KEY_1:
				set_evolution_level(1)
			KEY_2:
				set_evolution_level(2)
			KEY_3:
				set_evolution_level(3)
			KEY_4:
				set_evolution_level(4)
			KEY_5:
				set_evolution_level(5)
			KEY_6:
				set_evolution_level(6)
				
	elif ev is InputEventMouseButton:
			if ev.is_pressed():
				if ev.button_index == BUTTON_WHEEL_UP:
					set_evolution_level(min(GameManager.evolution_level + 1, 6))
				if ev.button_index == BUTTON_WHEEL_DOWN:
					set_evolution_level(max(GameManager.evolution_level - 1, 0))

				
func set_evolution_level(lv):
	GameManager.set_evolution_level(lv)
	number.set_digit(lv)
	if is_instance_valid(GameManager.true_player) and GameManager.true_player.is_in_group('enemy'):
		GameManager.true_player.toggle_enhancement(true)
		
func _on_SummonButton_body_entered(body):
	if body.is_in_group('host') and body.is_player:
		sprite.material.set_shader_param('intensity', 0)
		active = true
	
func _on_SummonButton_body_exited(body):
	if body.is_in_group('host') and body.is_player:
		sprite.material.set_shader_param('intensity', 1)
		active = false
