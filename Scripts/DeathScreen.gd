extends Popup




func _on_PlayAgainButton_pressed():
	GameManager.lerp_to_timescale(1)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://Scenes/MainMenu.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()
