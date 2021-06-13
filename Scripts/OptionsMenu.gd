extends Control



onready var resolutionButton = $videoSettings/resolutionButton
onready var fullscreenButton = $videoSettings/fullscreenButton

onready var masterSlider = $audioSettings/masterSlider
onready var musicSlider = $audioSettings/musicSlider
onready var effectsSlider = $audioSettings/effectsSlider


func _ready():
	$Video.connect("pressed", self, "video")
	$Audio.connect("pressed", self, "audio")
	$Controls.connect("pressed", self, "controls")
	$Back.connect("pressed", self, "back")
	resolutionButton.connect("item_selected", self, "resolution")
	fullscreenButton.connect("item_selected", self, "fullscreen")
	$audioSettings/masterMute.connect("pressed",self, "muteMaster")
	masterSlider.connect("value_changed",self, "masterVolume")
	$audioSettings/musicMute.connect("pressed",self, "muteMusic")
	musicSlider.connect("value_changed",self, "musicVolume")
	$audioSettings/effectsMute.connect("pressed",self, "muteEffects")
	effectsSlider.connect("value_changed",self, "effectsVolume")
	
	
	resolutionButton.add_item("640 x 360", 0)
	resolutionButton.add_item("1920 x 1080", 1)
	resolutionButton.visible = false
	
	if Options.resWidth == 640 and Options.resHeight == 360:
		resolutionButton.select(0)
	elif Options.resWidth == 1920 and Options.resHeight == 1080:
		resolutionButton.select(1)
	
	fullscreenButton.add_item("Fullscreen", 0)
	fullscreenButton.add_item("Windowed", 1)
	
	masterSlider.set_value(Options.masterVolume)
	musicSlider.set_value(Options.musicVolume)
	effectsSlider.set_value(Options.effectsVolume)
	
func video():
	$videoSettings.show()
	$audioSettings.hide()
	$controlSettings.hide()
	
func audio():
	$audioSettings.show()
	$videoSettings.hide()
	$controlSettings.hide()
	
func controls():
	$controlSettings.show()
	$audioSettings.hide()
	$videoSettings.hide()
	
func back():
	get_tree().change_scene("res://Scenes/Menus/StartMenu.tscn")
	
func resolution(item):
	match item:
		0:
			Options.resWidth = 640
			Options.resHeight = 360
			Options.resolution()
			Options.saveSettings()
		1:
			Options.resWidth = 1920
			Options.resHeight = 1080
			Options.resolution()
			Options.saveSettings()

func fullscreen(item):
	match item:
		0:
			Options.fullscreen = true
			resolutionButton.visible = false
			Options.resolution()
			Options.saveSettings()
		1:
			Options.fullscreen = false
			resolutionButton.visible = true
			Options.resolution()
			Options.saveSettings()

func muteMaster():
	if !Options.masterMute:
		Options.masterMute = true
	else:
		Options.masterMute = false
	Options.saveSettings()

func masterVolume(value):
	Options.masterVolume = masterSlider.get_value()
	Options.saveSettings()

func muteMusic():
	if !Options.musicMute:
		Options.musicMute = true
	else:
		Options.musicMute = false
	Options.saveSettings()

func musicVolume(value):
	Options.musicVolume = musicSlider.get_value()
	Options.saveSettings()

func muteEffects():
	if !Options.effectsMute:
		Options.effectsMute = true
	else:
		Options.effectsMute = false
	Options.saveSettings()

func effectsVolume(value):
	Options.effectsVolume = effectsSlider.get_value()
	Options.saveSettings()
