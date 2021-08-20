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
	1: "SkyRuins",
	2: "Labyrinth",
	3: "Desert"
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

var keybinds = {
	'move_up': KEY_W,
	'move_down': KEY_S,
	'move_left': KEY_A,
	'move_right': KEY_D,
	'swap': KEY_SPACE,
	'pause': KEY_ESCAPE,
}

#Game Stats
var high_scores = {
	"SkyRuins": 0,
	"Labyrinth": 0,
	"Desert": 0
}
var max_kills = {
	"SkyRuins": 0,
	"Labyrinth": 0,
	"Desert": 0
}
var max_time = {
	"SkyRuins": 0,
	"Labyrinth": 0,
	"Desert": 0
}
var max_EVL = {
	"SkyRuins": 1,
	"Labyrinth": 1,
	"Desert": 1
}
var enemy_kills = {
	Enemy.EnemyType.SHOTGUN: 0,
	Enemy.EnemyType.WHEEL: 0,
	Enemy.EnemyType.CHAIN: 0,
	Enemy.EnemyType.FLAME: 0,
	Enemy.EnemyType.ARCHER: 0,
	Enemy.EnemyType.EXTERMINATOR: 0,
	Enemy.EnemyType.SORCERER: 0,
	Enemy.EnemyType.SABER: 0,
	Enemy.EnemyType.UNKNOWN: 0
}

var enemy_deaths = {
	Enemy.EnemyType.SHOTGUN: 0,
	Enemy.EnemyType.WHEEL: 0,
	Enemy.EnemyType.CHAIN: 0,
	Enemy.EnemyType.FLAME: 0,
	Enemy.EnemyType.ARCHER: 0,
	Enemy.EnemyType.EXTERMINATOR: 0,
	Enemy.EnemyType.SORCERER: 0,
	Enemy.EnemyType.SABER: 0,
	Enemy.EnemyType.UNKNOWN: 0
}

var enemy_swaps = {
	Enemy.EnemyType.SHOTGUN: 0,
	Enemy.EnemyType.WHEEL: 0,
	Enemy.EnemyType.CHAIN: 0,
	Enemy.EnemyType.FLAME: 0,
	Enemy.EnemyType.ARCHER: 0,
	Enemy.EnemyType.EXTERMINATOR: 0,
	Enemy.EnemyType.SORCERER: 0,
	Enemy.EnemyType.SABER: 0,
	Enemy.EnemyType.UNKNOWN: 0
}

func _ready():
	loadSettings()
	choose_music()
	apply_audio_settings()
	resolution()
	set_keybinds()

func _process(delta):
	pass

func choose_music():
	if level == "Menu" and false:
		menuMusic()
	else:
		gameMusic()

func menuMusic():
	song = load("res://Sounds/Music/cuuuu b3.wav")
	$Music.set_stream(song)
	$Music.play(0.0)


func gameMusic():
	song = load("res://Sounds/Music/" + GameManager.level['music'])
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

func set_keybinds(): #modified from https://www.youtube.com/watch?v=I_Kzb-d-SvM
	for key in keybinds.keys():
		var scancode = keybinds[key]
		var actionlist = InputMap.get_action_list(key)
		if !actionlist.empty():
			InputMap.action_erase_event(key, actionlist[0])
		var new_key = InputEventKey.new()
		new_key.set_scancode(scancode)
		InputMap.action_add_event(key, new_key)

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
		"keybinds": keybinds,
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
	keybinds = data['keybinds']
	high_scores = data['high_scores']
	max_kills = data['max_kills']
	max_time = data['max_time']
	max_EVL = data['max_EVL']
	enemy_kills = data['enemy_kills']
	enemy_deaths = data['enemy_deaths']
	enemy_swaps = data['enemy_swaps']
