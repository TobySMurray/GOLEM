extends Popup


func _physics_process(delta):
	if Input.is_action_just_pressed("items"):
		self.show()
	if Input.is_action_just_released("items"):
		self.hide()
