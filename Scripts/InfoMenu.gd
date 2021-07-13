extends Control

func _ready():
	$GridContainer/EnemiesButton.connect("pressed", self, "enemies")
	$Back.connect("pressed", self, "back")
func _physics_process(delta):
	if Input.is_action_pressed("pause"):
		back()
func enemies():
	get_tree().change_scene("res://Scenes/Menus/EnemyInfoMenu.tscn")
func back():
	get_tree().change_scene("res://Scenes/Menus/StartMenu.tscn")
