extends "res://Scripts/Enemy.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var label = $Label
onready var release = $Label2

var forced = false


# Called when the node enters the scene tree for the first time.
func _ready():
	label.visible = false
	release.visible = false
	max_speed = 30
	score = 0

func _physics_process(delta):
	if !about_to_swap and GameManager.swappable:
		label.visible = true
		release.visible = false
	
	if about_to_swap:
		label.visible = false
		release.visible = true
		
	if self.is_in_group("enemy"):
		label.visible = false
		release.visible = false
		if not invincible:
			die()
	if GameManager.out_of_control and not forced:
		forced = true
		label.visible = false
		force()

func force():
	release.visible = true
	force_swap = true
	toggle_swap(true)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Die":
		label.visible = false
		release.visible = false
		actually_die()
