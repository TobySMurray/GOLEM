extends Node

# STATE MACHINE VARS
var current_state = ''
var last_state = ''

var state_timer = 0
var last_state_timer = 0

# ENEMY-LIKE VARS
var health = 100
var mass = 1

var stunned = false
var stun_timer = 0

func _physics_process(delta):
	process_state(delta, current_state)

func set_state(state):
	exit_state(current_state)
	enter_state(state)
	last_state = current_state
	current_state = state
	
func revert_state(restart = false):
	set_state(last_state)
	if not restart:
		state_timer = last_state_timer
	
func enter_state(state):
	pass
	
func exit_state(state):
	pass
	
func process_state(delta, state):
	pass
