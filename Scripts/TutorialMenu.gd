extends Control

onready var text = $Label
export(String, FILE, "*.tscn") var next

func _ready():
	$Back.connect("pressed", self, "back")
	$Next.connect("pressed", self, "next")
	text.text = "Move with " + OS.get_scancode_string(Options.keybinds["move_up"]) + OS.get_scancode_string(Options.keybinds["move_left"])  \
	+ OS.get_scancode_string(Options.keybinds["move_down"])  +  OS.get_scancode_string(Options.keybinds["move_right"]) + "\n" \
	+ "Hold down " + OS.get_scancode_string(Options.keybinds["swap"]) + " to possess enemies" + "\n" + "Attack with LMB \nSpecial with RMB"

func _physics_process(delta):
	if Input.is_action_pressed("pause"):
		back()

func back():
	get_tree().change_scene("res://Scenes/Menus/LevelSelect.tscn")

func next():
	get_tree().change_scene(next)
