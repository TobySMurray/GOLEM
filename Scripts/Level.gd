extends Node

export (NodePath) var init_player

func _ready():
	#Only necessary so level scenes can be run individually in the editor
	if not GameManager.world:
		GameManager.start_game('arcade', name, filename, true)
		 
	

