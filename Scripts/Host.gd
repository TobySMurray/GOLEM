extends KinematicBody2D
class_name Host

var is_player = false
var can_be_swapped_to = true
var uses_swap_bar = true
var override_swap_camera = false
export var debug_start_as_player = false

var max_swap_shield_health = 0
var swap_shield_health = 0

var time_since_controlled = 9999999

static func is_valid_swap_target(target):
	return target.is_in_group('host') and target.can_be_swapped_to and not target.is_player and target.swap_shield_health <= 0 and not (target.is_in_group('enemylike') and target.dead)

func _ready():
	if debug_start_as_player:
		is_player = true

func _physics_process(delta):
	if not is_player:
		time_since_controlled += delta

func toggle_playerhood(state):
	is_player = state
	time_since_controlled = 0
	

