extends Control


func _ready():
	GameManager.play_level_bgm('MainMenu')
	$Buttons/Play.pressed.connect(self, "play_campaign")
	$Buttons/Arcade.pressed.connect(self, "play_arcade")
	$Buttons/Options.pressed.connect(self, "options")
	$Buttons/Quit.pressed.connect( self, "quit")
	$Buttons/Stats.pressed.connect(self, "stats")
	GameManager.scene_transition.fade_in()
	GameManager.world = null

func play_campaign():
	GameManager.start_game('campaign', 'SkyRuins')

func play_arcade():
	get_tree().change_scene("res://Scenes/Menus/LevelSelect.tscn")
	
func options():
	get_tree().change_scene("res://Scenes/Menus/OptionsMenu.tscn")

func stats():
	get_tree().change_scene("res://Scenes/Menus/InfoMenu.tscn")
func quit():
	get_tree().quit()
