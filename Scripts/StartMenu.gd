extends Control


func _ready():
	GameManager.on_level_loaded('MainMenu')
	$Buttons/Arcade.connect("pressed", self, "play")
	$Buttons/Options.connect("pressed",self, "options")
	$Buttons/Quit.connect("pressed", self, "quit")
	$Buttons/Stats.connect("pressed", self, "stats")



func play():
	get_tree().change_scene("res://Scenes/Menus/LevelSelect.tscn")
	
func options():
	get_tree().change_scene("res://Scenes/Menus/OptionsMenu.tscn")

func stats():
	get_tree().change_scene("res://Scenes/Menus/InfoMenu.tscn")
func quit():
	get_tree().quit()
