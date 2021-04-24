extends "res://Scripts/Enemy.gd"

var shot_speed = 200
var shot_spread = 15
var num_pellets = 6

# Called when the node enters the scene tree for the first time.
func _ready():
	flip_offset = -53
	
func player_action():
	if Input.is_action_just_pressed("attack1"):
		for i in range(num_pellets):
			var pellet_dir = aim_direction.rotated((randf()-0.5)*deg2rad(shot_spread))
			var pellet_speed = shot_speed * (1 + 0.5*(randf()-0.5))
			shoot_bullet(pellet_dir*pellet_speed, 10)

