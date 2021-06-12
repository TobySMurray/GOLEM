extends Sprite

onready var background = get_node("../../EVLBackground")

var digit = 1
var is_animating = true
var anim_timer = 0
var anim_speed = 5.0
var digit_frame = 0

const digit_colors = [
	Color(0, 1, 0.86),
	Color(0.48, 0.87, 0.33),
	Color(0.87, 0.92, 0.34),
	Color(1, 0.49, 0),
	Color(1, 0, 0),
	Color(1, 0, 0.5),
	Color.white
]

func toggle_animation(state):
	is_animating = state
	digit_frame = 0
	anim_timer = 0
	update_sprite()
		
func _process(delta):
	if is_animating:
		anim_timer -= delta
		if anim_timer < 0:
			anim_timer = 1/anim_speed
			digit_frame = 0 if digit_frame == 1 else 1
			update_sprite()
			
func update_sprite():
	if digit < 1 or digit > 10:
		digit = 10
		
	background.modulate = digit_colors[clamp(digit-1, 0, 6)]
		
	position.x = -5 if digit == 1 else 0
	var frame = 2*(digit-1)+digit_frame
	region_rect = Rect2(64*(frame % 5), 64*int(frame / 5), 64, 64)

