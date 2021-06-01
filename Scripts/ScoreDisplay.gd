extends Label

export var decay = 1  # How quickly the shaking stops [0, 1].
export var max_dist = 5  # Maximum hor/ver shake in pixels.
export var max_roll = 0  # Maximum rotation in radians (use sparingly).
#export var color_fade_time = 0.5
#export var rave_intensity = 0

#export var color_pulse_enabled = false
#export var pulse_gradient : Gradient
#export var color_pulse_freq = 2
#export var color_pulse_range = 0.3



#var base_color
#export var color_pulse_offset = 0.0

var timer = 0
var increment_timer = 0
var base_pos
var trauma = 0.0  # Current shake strength.

var displayed_score = 0
export var score = 0

func _ready():
	base_pos = rect_position
	GameManager.score_display = get_parent()

func _process(delta):
	update_score_display(delta)
	
	if trauma > 0:
		shake()
		trauma = max(trauma - trauma*decay*delta, 0)
		if trauma < 0.2: 
			trauma = 0
			rect_position = base_pos
			rect_rotation = 0
		
func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)
	
func set_trauma(amount, use_max = true):
	if use_max:
		trauma = max(trauma, amount)
	else:
		trauma = amount

func shake():
	var amount = trauma/(10+trauma)
	rect_position = base_pos + max_dist * amount * Vector2(randf()-0.5, randf()-0.5)
	rect_rotation = max_roll * amount * (randf()-0.5)
	
func update_score_display(delta):
	if displayed_score != score:
		if increment_timer < 0:
			var dif = score - displayed_score
			set_trauma(sqrt(abs(dif)-1))
			if abs(dif) < 10:
				increment_timer = 0.4/abs(dif)
				displayed_score += sign(dif)
			else:
				increment_timer = 0.05
				displayed_score += int(dif/10)
			text = str(displayed_score)
			rect_pivot_offset.x = 7*len(str(displayed_score))
		else:
			increment_timer -= delta

