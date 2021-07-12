extends ColorRect

onready var anim = $AnimationPlayer

var destination_path = ''

func _enter_tree():
	print('transition ready')
	color = Color(0, 0, 0, 0)
	#anim = get_node("AnimationPlayer")
	get_parent().remove_child(self)
	
func fade_out(scene_path, time = 0.5):
	destination_path = scene_path
	anim.playback_speed = 1.0/time
	anim.play('Fade')
	
func fade_in(time = 0.5):
	destination_path = ''
	anim.playback_speed = 1.0/time
	anim.play_backwards('Fade')
	

func _on_AnimationPlayer_animation_finished(anim_name):
	if destination_path != '':
		get_tree().change_scene(destination_path)
