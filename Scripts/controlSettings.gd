extends Control
#modifed from https://www.youtube.com/watch?v=I_Kzb-d-SvM
onready var binds = $ScrollContainer/Binds
onready var buttonscript = load("res://Scripts/KeyButton.gd")

var keybinds
var buttons = {}

func _ready():
	binds.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	keybinds = Options.keybinds.duplicate()
	var attack1hbox = HBoxContainer.new()
	var attack1label = Label.new()
	var attack1control = Label.new()
	attack1hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	attack1label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	attack1control.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	attack1label.text = "Attack"
	attack1control.text = "LMB"
	attack1control.align = Label.ALIGN_CENTER
	attack1hbox.add_child(attack1label)
	attack1hbox.add_child(attack1control)
	binds.add_child(attack1hbox)
	var attack2hbox = HBoxContainer.new()
	var attack2label = Label.new()
	var attack2control = Label.new()
	attack2hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	attack2label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	attack2control.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	attack2label.text = "Special"
	attack2control.text = "RMB"
	attack2control.align = Label.ALIGN_CENTER
	attack2hbox.add_child(attack2label)
	attack2hbox.add_child(attack2control)
	binds.add_child(attack2hbox)
	for key in keybinds:
		var hbox = HBoxContainer.new()
		var label = Label.new()
		var button = Button.new()
		hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		button.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		if key == "move_up":
			label.text = "Move Up"
		if key == "move_down":
			label.text = "Move Down"
		if key == "move_left":
			label.text = "Move Left"
		if key == "move_right":
			label.text = "Move Right"
		if key == "swap":
			label.text = "Swap"
		if key == "pause":
			label.text = "Pause"
		var button_value = keybinds[key]
		button.text += OS.get_scancode_string(button_value)
		button.set_script(buttonscript)
		button.value = button_value
		button.key = key
		button.menu = self
		button.toggle_mode = true
		hbox.add_child(label)
		hbox.add_child(button)
		binds.add_child(hbox)
		buttons[key] = button
	
func change_bind(key, value):
	keybinds[key] = value
	for bind in keybinds:
		if bind != key and value != null and keybinds[bind] == value:
			keybinds[bind] = null
			buttons[bind].value = null
			buttons[bind].text = "Unassigned"

func _on_SaveKeybinds_pressed():
	Options.keybinds = keybinds.duplicate()
	Options.set_keybinds()
