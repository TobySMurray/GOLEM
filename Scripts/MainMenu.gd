extends Control


onready var credits = $CreditsPopup
onready var controls = $ControlsPopup
onready var level_select = $LevelSelectPopup
onready var Canvas = $CanvasModulate
onready var animplayer = $AnimationPlayer

const level_paths = {
	1: "MainLevel",
	2: "Level2"
}

var selected_level = 1
var skippable = false

func _ready():
	animplayer.play("FadeIn")
	
func _on_StartButton_pressed():
	level_select.popup()

func begin_level_intro(level_id):
	selected_level = level_id
	level_select.visible = false
	animplayer.play("FadeOut")


func _physics_process(_delta):
	if Input.is_action_just_pressed("swap") and skippable:
		animplayer.play("Transition")
		

func _on_ControlsButton_pressed():
	controls.popup()


func _on_CreditsButton_pressed():
	credits.popup()


func _on_ReturnButton_pressed():
	credits.visible = false
	level_select.visible = false


func _on_ControlsReturnButton_pressed():
	controls.visible = false

func start_level():
	get_tree().change_scene("res://Scenes/"+ level_paths[selected_level] +".tscn")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "FadeOut":
		animplayer.play("Story")
		skippable = true
	if anim_name == "Story":
		animplayer.play("Transition")



func _on_QuitButton_pressed():
	get_tree().quit()
