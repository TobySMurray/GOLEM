extends Control

func _ready():
	$GridContainer/EnemiesButton.connect("pressed", self, "enemies")
	$GridContainer/MiscButton.connect("pressed", self, "upgrades")
	$Back.connect("pressed", self, "back")
func _physics_process(delta):
	if Input.is_action_pressed("pause"):
		back()
func enemies():
	get_tree().change_scene("res://Scenes/Menus/EnemyInfoMenu.tscn")
func upgrades():
	get_tree().change_scene("res://Scenes/Menus/UpgradeInfoMenu.tscn")
func back():
	get_tree().change_scene("res://Scenes/Menus/StartMenu.tscn")
