extends Node2D

var transcender_curve = Curve2D.new()
var should_draw

func _draw():
	if should_draw:
		var curve_points = transcender_curve.tessellate()
		for i in len(curve_points) - 1:
			draw_line(curve_points[i], curve_points[i + 1], Color.crimson, 2)

func draw_transcender(curve):
	should_draw = true
	transcender_curve = curve
	update()
	
func clear_transcender():
	should_draw = false
	update()
