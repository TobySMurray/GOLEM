extends Popup

export(String, FILE, "*.tscn") var level


func _on_PlayAgainButton_pressed():
	GameManager.lerp_to_timescale(1)
	Engine.time_scale = 1
	
	var mode = 'arcade' if GameManager.arcade_mode else 'campaign'
	var level = GameManager.level_name if GameManager.arcade_mode else 'SkyRuins'
	var map = GameManager.fixed_map if GameManager.arcade_mode else null
	GameManager.start_game(mode, level, map)

func _on_QuitButton_pressed():
	GameManager.lerp_to_timescale(1)
	Engine.time_scale = 1
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameManager.scene_transition.fade_out_to_scene("res://Scenes/Menus/StartMenu.tscn", 0.25)
