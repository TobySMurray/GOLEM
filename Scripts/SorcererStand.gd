extends Area2D

onready var sprite = $AnimatedSprite
onready var collision = $CollisionShape2D

var timer = 0
var anchored_pos = Vector2.ZERO
var next_smack_vel = Vector2.ZERO

func _physics_process(delta):
	if visible:
		timer -= delta
		modulate.a = 0.7*sqrt(max(timer, 0))
		global_position = anchored_pos
		
		if timer < 0:
			hide()
		
func hide():
	visible = false
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
func set_pos(pos, dir):
	sprite.flip_h = dir < 0
	sprite.offset.x = -13 if dir < 0 else 0
	anchored_pos = pos
	global_position = anchored_pos
	
func conjure(pos, dir, attacking = true):
	timer = 1.2
	visible = true
	collision.set_deferred("disabled", false)
	modulate.a = 0.7
	
	if attacking:	
		sprite.frame = 0
		sprite.play('Attack')
		
	set_pos(pos, dir)
	
	
