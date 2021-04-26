extends "res://Scripts/Enemy.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	score = 0

func _physics_process(delta):
	if self.is_in_group("enemy"):
		if not invincible:
			die()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Die":
		queue_free()
