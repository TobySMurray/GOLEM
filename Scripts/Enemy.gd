extends KinematicBody2D

onready var animplayer = $AnimatinoPlayer
onready var sprite = $Sprite

var health
var max_speed = 100
var velocity = Vector2.ZERO
var accel = 1
var facing_left = false
var attacking = false
var about_to_swap = false

var is_player = false

func physics_process():
	if is_player:
		player_move()
	else:
		ai_move()
		
	#animate()
	
func player_move():
	var move_direction = Vector2.ZERO
	move_direction.x = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	move_direction.y = -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	
	if abs(move_direction.x > 0) or abs(move_direction.y > 0):
		velocity = lerp(velocity, max_speed * move_direction.normalized(), accel)
	else:
		velocity = lerp(velocity, Vector2.ZERO, accel)
		
func ai_move():
	pass
		
func animate():
	if not attacking:
		if velocity.x > 0.5:
			facing_left = false
			sprite.flip_h = false
		elif velocity.x < -0.5:
			facing_left = true
			sprite.flip_h = true
		else:
			sprite.flip_h = facing_left

	if abs(velocity.x) <= 20 and !attacking:
		animplayer.play("Idle")
	elif !attacking:
		animplayer.play("Walk")
		
func take_damage(damage):
	health -= damage
	if health <= 0:
		die()
	else:
		animplayer.play("Hit")
		
func toggle_playerhood(state):
	is_player = state
	#Whatever else has to happewn
		
func die():
	queue_free()
		
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

