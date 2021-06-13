extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$SkyRuins.connect("pressed", self, "skyRuins")
	$Labyrinth.connect("pressed", self, "labyrinth")
	$Desert.connect("pressed", self, "desert")
	$Back.connect("pressed", self, "back")


func skyRuins():
	pass
	
func labyrinth():
	pass
	
func desert():
	pass
	
func back():
	get_tree().change_scene("res://Scenes/Menus/StartMenu.tscn")
