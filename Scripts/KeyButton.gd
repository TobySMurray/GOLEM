extends Button


var key
var value
var menu

var waiting_for_input = false

func _input(event):
	if waiting_for_input:
		if event is InputEventKey:
			value = event.scancode
			if key == "attack1":
				text = "LMB, " + OS.get_scancode_string(value)
			elif key == "attack2":
				text = "RMB, " + OS.get_scancode_string(value)
			else:
				text = OS.get_scancode_string(value)
				menu.change_bind(key, value)
			pressed = false
			waiting_for_input = false
		if event is InputEventMouseButton:
			if value != null:
				text = OS.get_scancode_string(value)
			else:
				text = "Unassigned"
			pressed = false
			waiting_for_input = false

func _toggled(button_pressed):
	if button_pressed:
		waiting_for_input = true
		set_text("Press any key...")
