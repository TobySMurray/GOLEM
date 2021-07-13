extends Control

export var decay = 1  # How quickly the shaking stops [0, 1].
export var max_dist = 5  # Maximum hor/ver shake in pixels.
export var max_roll = 0  # Maximum rotation in radians (use sparingly).
export var color_fade_time = 0.5
export var rave_intensity = 0

export var color_pulse_enabled = false
export var pulse_gradient : Gradient
export var color_pulse_freq = 2
export var color_pulse_range = 0.3

var base_color
export var color_pulse_offset = 0.0

var timer = 0
var increment_timer = 0
var base_pos
var trauma = 0.0  # Current shake strength.

var displayed_score = 0
export var score = 0

func _ready():
	base_pos = rect_position
	base_color = modulate

func _process(delta):
	if trauma > 0:
		shake()
		trauma = max(trauma - trauma*decay*delta, 0)
	
func set_trauma(amount, use_max = true):
	if use_max:
		trauma = max(trauma, amount)
	else:
		trauma = amount

func shake():
	var amount  = trauma/(10+trauma)
	rect_position = base_pos + max_dist * amount * Vector2(randf()-0.5, randf()-0.5)
	rect_rotation = max_roll * amount * (randf()-0.5)
