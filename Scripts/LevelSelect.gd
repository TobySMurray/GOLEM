extends Control



const level_paths = {
	0: "Menu",
	1: "SkyRuins1",
	2: "Labyrinth1",
	3: "Desert1"
}

func _ready():
	$SkyRuins.pressed.connect(self, "skyRuins")
	$Labyrinth.pressed.connect(self, "labyrinth")
	$Desert.pressed.connect(self, "desert")
	$Back.pressed.connect( self, "back")
	$HowTo.pressed.connect(self, "HowTo")
	
	var r_time = Options.max_time["SkyRuins"]
	var l_time = Options.max_time["Labyrinth"]
	var d_time = Options.max_time["Desert"]
	
	$SkyRuins/SkyRuinsStats.text = 'HIGH SCORE: ' + str(Options.high_scores['SkyRuins']) + '\nBEST TIME: ' + str(int(r_time/60)) + (':' if int(r_time)%60 > 9 else ':0') + str(int(r_time)%60)
	$Labyrinth/LabyrinthStats.text = 'HIGH SCORE: ' + str(Options.high_scores['Labyrinth']) + '\nBEST TIME: ' + str(int(l_time/60)) + (':' if int(l_time)%60 > 9 else ':0') + str(int(l_time)%60)
	$Desert/DesertStats.text = 'HIGH SCORE: ' + str(Options.high_scores['Desert']) + '\nBEST TIME: ' + str(int(d_time/60)) + (':' if int(d_time)%60 > 9 else ':0') + str(int(d_time)%60)
	
func _physics_process(delta):
	if Input.is_action_pressed("pause"):
		back()
func skyRuins():
	#get_tree().change_scene("res://Scenes/Levels/"+ level_paths[1] +".tscn")
	#GameManager.scene_transition.fade_out("res://Scenes/Levels/"+ level_paths[1] +".tscn")
	GameManager.start_game('arcade', 'SkyRuins', "res://Scenes/Levels/"+ level_paths[1] +".tscn")
	
func labyrinth():
	#get_tree().change_scene("res://Scenes/Levels/"+ level_paths[2] +".tscn")
	#GameManager.scene_transition.fade_out("res://Scenes/Levels/"+ level_paths[2] +".tscn")
	GameManager.start_game('arcade', 'Labyrinth', "res://Scenes/Levels/"+ level_paths[2] +".tscn")

func desert():
	#GameManager.scene_transition.fade_out("res://Scenes/Levels/"+ level_paths[3] +".tscn")
	GameManager.start_game('arcade', 'Desert', "res://Scenes/Levels/"+ level_paths[3] +".tscn")
	
func back():
	get_tree().change_scene("res://Scenes/Menus/StartMenu.tscn")
	
	
func HowTo():
	get_tree().change_scene("res://Scenes/Menus/TutorialMenu.tscn")
