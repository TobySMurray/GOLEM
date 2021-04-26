extends TextureProgress

var max_control_time = 15
var swap_threshold = 1

var control_timer = 0

onready var tween = $Tween
onready var threshold = $Threshold

func _ready():
	self.value = 0
	GameManager.swap_bar = self
	threshold.max_value = max_control_time
	threshold.value = swap_threshold

func _physics_process(delta):
	control_timer = min(control_timer + delta, 100)
	
	if Input.is_action_just_pressed("reset"):
		control_timer = 0
	
	self.value = (control_timer / max_control_time) * 100
	tween.interpolate_property(self, "value", self.value, control_timer, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.2)
	tween.start()
	
	GameManager.swappable = control_timer > swap_threshold
	
	if control_timer > max_control_time - 5:
		GameManager.toggle_out_of_control(true)

