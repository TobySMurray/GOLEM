extends Node2D

onready var animplayer= $AnimationPlayer
onready var canvas = $CanvasModulate

func _ready():
	animplayer.play("FadeIn")
	
