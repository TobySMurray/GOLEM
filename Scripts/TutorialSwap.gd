extends Control


export(String, FILE, "*.tscn") var back
export(String, FILE, "*.tscn") var next

func _ready():
	$TutorialBack.connect("pressed", self, "back")
	$Back.connect("pressed", self, "menu")
	$Next.connect("pressed", self, "next")

func _physics_process(delta):
	if Input.is_action_pressed("pause"):
		back()

func menu():
	get_tree().change_scene("res://Scenes/Menus/LevelSelect.tscn")

func back():
	get_tree().change_scene(back)

func next():
	get_tree().change_scene(next)
