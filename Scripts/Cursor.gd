extends Node2D



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_viewport().warp_mouse(Vector2(120, 80))
	
	
func _process(delta):
	self.position = self.get_global_mouse_position()
