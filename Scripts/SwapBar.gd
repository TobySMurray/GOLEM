extends TextureProgress


onready var timer = $SwapTimer
onready var tween = $UpdateTween


var cooldown = 30
var swap_threshold = 15

func _ready():
	timer.wait_time = cooldown
	self.value = 0

func _physics_process(delta):
	if Input.is_action_just_pressed("move_up"):
		timer.start()
	
	self.value = int((timer.time_left / cooldown) * 100)
	
	if timer.time_left > swap_threshold:
		GameManager.swappable = false
	
	if timer.time_left < swap_threshold:
		GameManager.swappable = true
	
	if timer.time_left < 5:
		GameManager.out_of_control()

