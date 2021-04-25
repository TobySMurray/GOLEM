extends Area2D

onready var anim = $AnimatedSprite

var victims = []

var damage = 0
var force = 0
var delay_timer = 0
var exploded = false

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _process(delta):
	delay_timer -= delta
	if not exploded and delay_timer < 0:
		explode()
		
	if delay_timer < -2:
		queue_free()
		
func explode():
	exploded = true
	anim.frame = 0
	anim.play("Explode")
	
	for victim in victims:
		if not victim.invincible:
			victim.take_damage(damage)
			victim.velocity += (victim.global_position - global_position).normalized() * force


func _on_Explosion_area_entered(area):
	if area.is_in_group("hitbox"):
		if not area.get_parent() in victims:
			victims.append(area.get_parent())


func _on_Explosion_area_exited(area):
	if area.is_in_group("hitbox"):
		if area.get_parent() in victims:
			victims.erase(area.get_parent())
