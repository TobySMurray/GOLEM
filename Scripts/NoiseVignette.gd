extends TextureRect

func _ready():
	material.set_shader_param('ALPHA_SHIFT', -1)
	
func _physics_process(delta):
	var intensity = pow(clamp(1 + (GameManager.swap_bar.control_timer - GameManager.swap_bar.max_control_time + 0.2)/5.0, 0, 1), 1)
	material.set_shader_param('ALPHA_SHIFT', intensity*(0.5 if GameManager.level['dark'] else 1) - 1)
	
	var red = max(0, intensity)
	material.set_shader_param('color', Vector3(0.8, 1.0 - red, 1.0 - red))
