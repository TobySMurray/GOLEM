extends Label

onready var mult_display_1 = get_node("../Multiplier1")
onready var mult_display_2 = get_node("../Multiplier2")

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
var score = 0

var variety_mult = 1.0
var overkill_mult = 1.0


func _ready():
	base_pos = rect_position
	GameManager.game_HUD = get_parent().get_parent()
	
	mult_display_1.trauma = 3
	mult_display_2.trauma = 3

func _process(delta):
	update_score_display(delta)
	update_multipliers()
	
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
			
func update_multipliers():
	if GameManager.swap_bar:
		var variety_mult = GameManager.variety_bonus
		var overkill_mult = 1.5 if GameManager.swap_bar.swap_threshold == 0 else 1.0
		
		mult_display_1.text = ""
		mult_display_2.text = ""
		
		var t = sin(GameManager.game_time*2)*0.5 + 0.5
		mult_display_1.modulate = Color.white.linear_interpolate(Color(0.97, 0, 0.57) if variety_mult >= 1 else Color(0.43, 0, 1), t)
		mult_display_2.modulate = Color.white.linear_interpolate(Color(0.97, 0, 0.57), 1-t)
		
		
		if variety_mult != 1.0:
			mult_display_1.text = "x" + str(variety_mult) + (" Variety" if variety_mult > 1.0 else " Repeat")
		
		if overkill_mult != 1.0:
			if variety_mult != 1.0:
				mult_display_2.text = "x1.5 Overkill"
			else:
				mult_display_1.text = "x1.5 Overkill"
			
		

