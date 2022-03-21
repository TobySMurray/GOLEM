extends Control

func _ready():
	$GridContainer/EnemiesButton.pressed.connect(self, "enemies")
	$GridContainer/MiscButton.pressed.connect(self, "upgrades")
	$Back.pressed.connect(self, "back")
func _physics_process(delta):
	if Input.is_action_pressed("pause"):
		back()
func enemies():
	get_tree().change_scene("res://Scenes/Menus/EnemyInfoMenu.tscn")
func upgrades():
	get_tree().change_scene("res://Scenes/Menus/UpgradeInfoMenu.tscn")
func back():
	get_tree().change_scene("res://Scenes/Menus/StartMenu.tscn")
