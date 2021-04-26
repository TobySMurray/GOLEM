extends Control


onready var credits = $CreditsPopup
onready var controls = $ControlsPopup
onready var Canvas = $CanvasModulate
onready var animplayer = $AnimationPlayer
onready var story = $Story


func _ready():
	animplayer.play("FadeIn")

func _on_StartButton_pressed():
	animplayer.play("FadeOut")


func _on_ControlsButton_pressed():
	controls.popup()


func _on_CreditsButton_pressed():
	credits.popup()


func _on_ReturnButton_pressed():
	credits.visible = false


func _on_ControlsReturnButton_pressed():
	controls.visible = false

func start_game():
	get_tree().change_scene("res://Scenes/MainLevel.tscn")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "FadeOut":
		animplayer.play("Story")
	if anim_name == "Story":
		animplayer.play("Transition")
