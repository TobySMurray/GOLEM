extends Area2D

export var destination = 'Labyrinth1'
export var accessible = true

func _ready():
	set_accessible(accessible)

func set_accessible(state):
	accessible = state
	modulate = Color.white if state else Color.gray
	#collision_layer = 4 if state else 0
	
func toggle_playerhood(state):
	GameManager.scene_transition.fade_out("res://Scenes/Levels/"+ destination +".tscn")
	GameManager.camera.anchor = self
	#get_tree().change_scene("res://Scenes/Levels/"+ destination +".tscn")
