extends Control

var lifetime
var color

# Called when the node enters the scene tree for the first time.
func _ready():
	color = Color(0.97, 0, 0.57)
	lifetime = 1.5
	
func _process(delta):
	modulate = color if int(lifetime*20)%2 == 0 else Color.white
	rect_position += Vector2.UP*max(lifetime-0.5, 0)*60*delta
	lifetime -= delta
	
	if lifetime < 0:
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
