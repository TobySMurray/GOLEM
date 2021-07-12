extends Control



const level_paths = {
	0: "Menu",
	1: "SkyRuins1",
	2: "Labyrinth1"
}

func _ready():
	$SkyRuins.connect("pressed", self, "skyRuins")
	$Labyrinth.connect("pressed", self, "labyrinth")
	$Desert.connect("pressed", self, "desert")
	$Back.connect("pressed", self, "back")

func skyRuins():
	#get_tree().change_scene("res://Scenes/Levels/"+ level_paths[1] +".tscn")
	GameManager.scene_transition.fade_out("res://Scenes/Levels/"+ level_paths[1] +".tscn")
	
func labyrinth():
	#get_tree().change_scene("res://Scenes/Levels/"+ level_paths[2] +".tscn")
	GameManager.scene_transition.fade_out("res://Scenes/Levels/"+ level_paths[2] +".tscn")

func desert():
	pass
	
func back():
	get_tree().change_scene("res://Scenes/Menus/StartMenu.tscn")
