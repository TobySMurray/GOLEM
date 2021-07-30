extends Control



onready var resolutionButton = $videoSettings/resolutionButton
onready var fullscreenButton = $videoSettings/fullscreenButton

onready var masterSlider = $audioSettings/masterVolumeSlider
onready var musicSlider = $audioSettings/musicVolumeSlider
onready var effectsSlider = $audioSettings/effectsVolumeSlider

onready var master_mute_btn = $audioSettings/masterMute
onready var music_mute_btn = $audioSettings/musicMute
onready var effects_mute_btn = $audioSettings/effectsMute


func _ready():
	$HBoxContainer/Video.connect("pressed", self, "video")
	$HBoxContainer/Audio.connect("pressed", self, "audio")
	$HBoxContainer/Controls.connect("pressed", self, "controls")
	$Back.connect("pressed", self, "back")
	resolutionButton.connect("item_selected", self, "resolution")
	fullscreenButton.connect("item_selected", self, "fullscreen")
	master_mute_btn.connect("pressed",self, "muteMaster")
	masterSlider.connect("value_changed",self, "masterVolume")
	music_mute_btn.connect("pressed",self, "muteMusic")
	musicSlider.connect("value_changed",self, "musicVolume")
	effects_mute_btn.connect("pressed",self, "muteEffects")
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
	
	masterSlider.value = Options.masterVolume
	musicSlider.value = Options.musicVolume
	effectsSlider.value = Options.effectsVolume
	
	master_mute_btn.pressed = Options.masterMute
	music_mute_btn.pressed = Options.musicMute
	effects_mute_btn.pressed = Options.effectsMute
	
	if Options.fullscreen:
		$videoSettings/fullscreenButton.selected = 0
		resolutionButton.visible = false
	else:
		$videoSettings/fullscreenButton.selected = 1
		resolutionButton.visible = true
	
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
	Options.saveSettings()
	$'.'.visible = false
	
func resolution(item):
	match item:
		0:
			Options.resWidth = 640
			Options.resHeight = 360

		1:
			Options.resWidth = 1920
			Options.resHeight = 1080
			
	Options.resolution()


func fullscreen(item):
	match item:
		0:
			Options.fullscreen = true
			resolutionButton.visible = false

		1:
			Options.fullscreen = false
			resolutionButton.visible = true
			
	Options.resolution()

func muteMaster():
	if !Options.masterMute:
		Options.masterMute = true
	else:
		Options.masterMute = false
	Options.apply_audio_settings()

func masterVolume(value):
	Options.masterVolume = masterSlider.get_value()
	Options.apply_audio_settings()

func muteMusic():
	if !Options.musicMute:
		Options.musicMute = true
	else:
		Options.musicMute = false
	Options.apply_audio_settings()

func musicVolume(value):
	Options.musicVolume = musicSlider.get_value()
	Options.apply_audio_settings()

func muteEffects():
	if !Options.effectsMute:
		Options.effectsMute = true
	else:
		Options.effectsMute = false
	Options.apply_audio_settings()

func effectsVolume(value):
	Options.effectsVolume = effectsSlider.get_value()
	Options.apply_audio_settings()
