extends "res://Scripts/Enemy.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var label = $Label
# Called when the node enters the scene tree for the first time.
func _ready():
	max_speed = 30
	score = 0

func _physics_process(delta):
	if GameManager.swappable:
		label.visible = true
	
	if self.is_in_group("enemy"):
		label.visible = false
		if not invincible:
			die()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Die":
		actually_die()
