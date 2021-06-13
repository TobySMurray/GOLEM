extends Control
#credit to Let's Make Games tutorial for structure help

#Temp
const SAVE_PATH = "res://save.json"
var settings = {}
var playMusic = 1
var playEffects = 1
var newChoice = 1
var song
var menu = true
#Saved
var masterVolume = 2000
var musicVolume = 2000
var effectsVolume = 2000
var masterMute = false
var musicMute = false
var effectsMute = false
var resWidth = 1920
var resHeight = 1080
var fullscreen = false

func _ready():
	loadSettings()
	chooseMusic()
	resolution()

func _process(delta):
	if !$Music.is_playing():
		chooseMusic()
	if masterVolume > 0 and musicVolume > 0 and !masterMute and !musicMute:
		playMusic = int((masterVolume/2000) * (musicVolume/2000) * 2000)
	else:
		playMusic = 1
	if masterVolume > 0 and effectsVolume > 0 and !masterMute and !effectsMute:
		playEffects = int((masterVolume/2000) * (effectsVolume/2000) * 2000)
	else:
		playEffects = 1
	$Music.set_max_distance(playMusic)

func chooseMusic():
	if menu:
		menuMusic()
	else:
		gameMusic()

func menuMusic():
	song = load("res://Sounds/Music/cuuuu b3.wav")
	$Music.set_stream(song)
	$Music.play(0.0)


func gameMusic():
	pass

func resolution():
	ProjectSettings.set_setting("display/window/size/width", resWidth)
	ProjectSettings.set_setting("display/window/size/test_width", resWidth)
	ProjectSettings.set_setting("display/window/size/width", resHeight)
	ProjectSettings.set_setting("display/window/size/test_height", resHeight)
	OS.set_window_size(Vector2(resWidth, resHeight))
	
	if fullscreen:
		OS.set_window_fullscreen(false)
		OS.set_window_fullscreen(true)
	else:
		OS.set_window_fullscreen(true)
		OS.set_window_fullscreen(false)
		OS.set_window_position(Vector2(0,0))
		
func saveSettings():
	var settings = {
		resolution = {
			width = resWidth,
			height = resHeight
		},
		fullscreen = fullscreen,
		masterVolume = masterVolume,
		masterMute = masterMute,
		musicVolume = masterVolume,
		musicMute = musicMute,
		effectsVolume = effectsVolume,
		effectsMute = effectsMute
		
	}
	var saveFile = File.new()
	saveFile.open(SAVE_PATH, File.WRITE)
	saveFile.store_line(to_json(settings))
	saveFile.close()

func loadSettings():
	var saveFile = File.new()
	if !saveFile.file_exists(SAVE_PATH):
		return
	saveFile.open(SAVE_PATH, File.READ)
	
	var data= {}
	data = parse_json(saveFile.get_as_text())
	masterVolume = data['masterVolume']
	musicVolume = data['musicVolume']
	effectsVolume = data['effectsVolume']
	masterMute = data['masterMute']
	musicMute = data['musicMute']
	effectsMute = data['effectsMute']
	resWidth = data['resolution']['width']
	resHeight = data['resolution']['height']
	fullscreen = data['fullscreen']
