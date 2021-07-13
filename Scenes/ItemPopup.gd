extends Control

onready var timer = $Timer
var time = 1.0

func _ready():
	timer.set_wait_time(time) 

func _physics_process(delta):
	if Input.is_action_pressed("swap"):
		show()
func show():
	$AnimationPlayer.play("FadeIn")
	timer.start()

func hide():
	$AnimationPlayer.play("FadeOut")

func _on_Timer_timeout():
	hide()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "FadeOut":
		queue_free()
