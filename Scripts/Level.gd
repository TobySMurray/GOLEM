extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.on_level_loaded(name)
	#Options.choose_music()
	
	

