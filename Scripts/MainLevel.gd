extends "res://Scripts/Level.gd"

func _ready():
	#animplayer.play("FadeIn")
	GameManager.load_level_props(name)
	Options.level = "SkyRuins"
	Options.chooseMusic()
	

