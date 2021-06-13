extends Popup


var paused = false
onready var timer = $Timer

func _physics_process(delta):
	if Input.is_action_just_pressed("pause") and not paused:
		toggle_pause(true)
		timer.start()
	if Input.is_action_just_pressed("pause") and paused and timer.is_stopped():
		toggle_pause(false)

func toggle_pause(state):
	paused = state
	self.visible = state
	get_tree().paused = state

func _on_PlayAgainButton_pressed():
	toggle_pause(false)

func _on_QuitButton_pressed():
	toggle_pause(false)
	GameManager.lerp_to_timescale(1)
	GameManager.reset()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene("res://Scenes/Menus/MainMenu.tscn")

