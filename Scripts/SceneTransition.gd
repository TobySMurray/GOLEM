extends ColorRect

onready var anim = $AnimationPlayer

var destination_path = ''
var destination_level = ''
var fixed_map = null
var restart_on_fadeout = false

func _enter_tree():
	color = Color(0, 0, 0, 0)
	#anim = get_node("AnimationPlayer")
	#get_parent().call_deferred('remove_child', self)
	
func fade_out_to_scene(scene_path, time = 0.5):
	destination_path = scene_path
	anim.playback_speed = 1.0/max(time, 0.01)
	anim.play('Fade')
	
func fade_out_to_level(level, fixed_map_ = null):
	destination_level = level
	fixed_map = fixed_map_
	anim.play('Fade')
	
func fade_out_and_restart(time = 0.5):
	restart_on_fadeout = true
	anim.playback_speed = 1.0/max(time, 0.01)
	anim.play('Fade')
	
func fade_in(time = 0.5):
	destination_path = ''
	destination_level = ''
	restart_on_fadeout = false
	anim.playback_speed = 1.0/time
	anim.play_backwards('Fade')
	

func _on_AnimationPlayer_animation_finished(anim_name):
	if restart_on_fadeout:
		GameManager.on_world_loaded()
	elif destination_path != '':
		get_tree().change_scene(destination_path)
	elif destination_level != '':
		GameManager.world.load_level(destination_level, fixed_map)
			
	
