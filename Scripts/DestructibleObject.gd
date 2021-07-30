extends Node2D

var invincible = false
var velocity = Vector2.ZERO
var mass = 999

func _ready():
	$Area2D.add_to_group('hitbox')
	add_to_group('bloodless')
	$Area2D.collision_layer = 4
	#$Area2D.connect("area_entered", self, "destroy")

func take_damage(source, damage, stun = 0):
	destroy()

func destroy():
	if $Sprite.visible:
		$Sprite.visible = false
		$Particles2D.emitting = true
		$Destroyed.visible = true
