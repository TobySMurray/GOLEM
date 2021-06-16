extends Control
#credit to Let's Make Games tutorial for structure help

#Temp
const SAVE_PATH = "res://save.json"
var settings = {}
var playMusic = 1
var playEffects = 1
var newChoice = 1
var song
const level_paths = {
	0: "Menu",
	1: "MainLevel",
	2: "Level2"
}
var level = level_paths[0]
#Saved
var masterVolume = db2linear(AudioServer.get_bus_volume_db(0))
var musicVolume = db2linear(AudioServer.get_bus_volume_db(1))
var effectsVolume = db2linear(AudioServer.get_bus_volume_db(2))
var masterMute = false
var musicMute = false
var effectsMute = false
var resWidth = 1920
var resHeight = 1080
var fullscreen = false

#Game Stats
var high_scores = {
	"RuinsLevel": 0,
	"LabyrinthLevel": 0,
	"DesertLevel": 0
}
var max_kills = {
	"RuinsLevel": 0,
	"LabyrinthLevel": 0,
	"DesertLevel": 0
}
var max_time = {
	"RuinsLevel": 0,
	"LabyrinthLevel": 0,
	"DesertLevel": 0
}
var max_EVL = {
	"RuinsLevel": 1,
	"LabyrinthLevel": 1,
	"DesertLevel": 1
}
var enemy_kills = {
	'shotgun': 0,
	'wheel': 0,
	'chain': 0,
	'flame': 0,
	'archer': 0,
	'exterminator': 0,
	'sorcerer': 0,
	'saber': 0
}

var enemy_deaths = {
	'shotgun': 0,
	'wheel': 0,
	'chain': 0,
	'flame': 0,
	'archer': 0,
	'exterminator': 0,
	'sorcerer': 0,
	'saber': 0
}

var enemy_swaps = {
	'shotgun': 0,
	'wheel': 0,
	'chain': 0,
	'flame': 0,
	'archer': 0,
	'exterminator': 0,
	'sorcerer': 0,
	'saber': 0
}

func _ready():
	loadSettings()
	chooseMusic()
	apply_audio_settings()
	resolution()

func _process(delta):
	pass

func chooseMusic():
	if level == "Menu":
		menuMusic()
	else:
		gameMusic()

func menuMusic():
	song = load("res://Sounds/Music/cuuuu b3.wav")
	$Music.set_stream(song)
	$Music.play(0.0)


func gameMusic():
	song = load("res://Sounds/Music/melon b3.wav")
	$Music.set_stream(song)
	$Music.play(0.0)

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
		
func apply_audio_settings():
	AudioServer.set_bus_volume_db(0, linear2db(0 if masterMute else masterVolume))
	AudioServer.set_bus_volume_db(1, linear2db(0 if musicMute else musicVolume))
	AudioServer.set_bus_volume_db(2, linear2db(0 if effectsMute else effectsVolume))
		
func saveSettings():
	var settings = {
		resolution = {
			width = resWidth,
			height = resHeight
		},
		"fullscreen": fullscreen,
		"masterVolume": masterVolume,
		"masterMute": masterMute,
		"musicVolume": musicVolume,
		"musicMute": musicMute,
		"effectsVolume": effectsVolume,
		"effectsMute": effectsMute,
		
		"high_scores": high_scores,
		"max_kills": max_kills,
		"max_time": max_time,
		"max_EVL": max_EVL,
		"enemy_kills": enemy_kills,
		"enemy_deaths": enemy_deaths,
		"enemy_swaps": enemy_swaps
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
	
	high_scores = data['high_scores']
	max_kills = data['max_kills']
	max_time = data['max_time']
	max_EVL = data['max_EVL']
	enemy_kills = data['enemy_kills']
	enemy_deaths = data['enemy_deaths']
	enemy_swaps = data['enemy_swaps']
