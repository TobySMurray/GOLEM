extends Node2D

var transcender_curve = Curve2D.new()
var should_draw = false
var enemy_is_selected = false

func _draw():
	if should_draw:
		var color = (Color.crimson if int(GameManager.game_time*80)%2 == 0 else Color.white) if enemy_is_selected else Color(0.86, 0.08, 0.24, 0.3)
		var curve_points = transcender_curve.tessellate()
		for i in len(curve_points) - 1:
			draw_line(curve_points[i], curve_points[i + 1], color, 2, true)

func draw_transcender(curve):
	should_draw = true
	transcender_curve = curve
	update()
	
func clear_transcender():
	should_draw = false
	update()

func toggle_selected_enemy(_enemy_is_selected):
	enemy_is_selected = _enemy_is_selected
	update()
