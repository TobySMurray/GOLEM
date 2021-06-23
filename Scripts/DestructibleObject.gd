extends Node2D


func _ready():
	$Area2D.connect("area_entered", self, "destroy")



func destroy():
	if $Sprite.visible:
		$Sprite.visible = false
		$Particles2D.emitting = true
		$Destroyed.visible = true
