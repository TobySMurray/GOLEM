extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Play.connect("pressed", self, "play")
	$Options.connect("pressed",self, "options")
	$Quit.connect("pressed", self, "quit")


func play():
	get_tree().change_scene("res://Scenes/Menus/LevelSelect.tscn")
	
func options():
	get_tree().change_scene("res://Scenes/Menus/OptionsMenu.tscn")

func quit():
	get_tree().quit()
