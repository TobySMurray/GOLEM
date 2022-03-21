extends Button

const button_audio = preload('res://Sounds/SoundEffects/Bloop1.wav')
@onready var audio_player = GameManager.get_node('MenuSFX')

@export var pitch = 1.0

func pressed():
	audio_player.stream = button_audio
	audio_player.pitch_scale = pitch
	audio_player .play()
