extends Popup




func _on_PlayAgainButton_pressed():
	GameManager.lerp_to_timescale(1)
	get_tree().reload_current_scene()
	GameManager.audio = get_node("/root/MainLevel/AudioStreamPlayer")

func _on_QuitButton_pressed():
	get_tree().quit()
