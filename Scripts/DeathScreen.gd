extends Popup




func _on_PlayAgainButton_pressed():
	GameManager.lerp_to_timescale(1)
	GameManager.reset()
	get_tree().reload_current_scene()

func _on_QuitButton_pressed():
	GameManager.lerp_to_timescale(1)
	GameManager.reset()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
