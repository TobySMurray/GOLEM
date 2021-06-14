extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var credits = $CreditsPopup

# Called when the node enters the scene tree for the first time.
func _ready():
	$Play.connect("pressed", self, "play")
	$Options.connect("pressed",self, "options")
	$Quit.connect("pressed", self, "quit")
	$Credits.connect("pressed", self, "toggle_credits")


func play():
	get_tree().change_scene("res://Scenes/Menus/LevelSelect.tscn")
	
func options():
	get_tree().change_scene("res://Scenes/Menus/OptionsMenu.tscn")

func quit():
	get_tree().quit()

func toggle_credits():
	if credits.visible:
		credits.visible = false
	else:
		credits.visible = true
