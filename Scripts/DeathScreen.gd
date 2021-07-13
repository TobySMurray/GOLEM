extends Popup

export(String, FILE, "*.tscn") var level


func _on_PlayAgainButton_pressed():
	GameManager.lerp_to_timescale(1)
	Engine.time_scale = 1
	GameManager.reset()
	#get_tree().change_scene(level)
	GameManager.scene_transition.fade_out('res://Scenes/Levels/'+ GameManager.level['scene_name'])

func _on_QuitButton_pressed():
	GameManager.lerp_to_timescale(1)
	Engine.time_scale = 1
	GameManager.reset()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Options.level = "Menu"
	Options.choose_music()
	get_tree().change_scene("res://Scenes//Menus/StartMenu.tscn")
