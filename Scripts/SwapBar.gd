extends TextureProgress

var max_control_time = 20.0
var init_swap_threshold = 1
var bar_min_value = 86
var bar_max_value = 925
var thresh_min_value = 81
var thresh_max_value = 928

var control_timer = 0.0
var swap_threshold = 0.0
var swap_threshold_penalty = 0
var unlocked_last_frame = false

var beep_timer = 0

var item_count = 2

onready var threshold = $Threshold
onready var warning_audio = $WarningAudio
onready var unlocked_audio = $UnlockedAudio
onready var screen_effect = $ScreenEffect
onready var warning = preload("res://Sounds/SoundEffects/warning.wav")
onready var ready = preload("res://Sounds/SoundEffects/moonready.wav")

onready var item_indicator = $ItemProgress
onready var Static = $Static

var colors = [Color(1,0.8,0.8,1),Color(1,0.5,0.5,1), Color(1,1,1,1)]
		
func _ready():
	control_timer = 15
	item_indicator.value = item_count * 100
	set_swap_threshold(init_swap_threshold)
	GameManager.swap_bar = self
	GameManager.connect("on_swap", self, "on_GM_swap")
	

func _physics_process(delta):
	control_timer = min(control_timer + delta, max_control_time)
	beep_timer -= 0.016
	if not GameManager.true_player or not GameManager.true_player.dead:
		self.value = (control_timer / max_control_time)*(bar_max_value - bar_min_value) + bar_min_value
		GameManager.swappable = control_timer > swap_threshold
	if control_timer < max_control_time - 3:
		in_control()
		Static.modulate.a = 0
	elif control_timer < max_control_time - 0.1:
		Static.modulate.a = 1 - (max_control_time - control_timer)/3
		out_of_control()
	elif GameManager.true_player and not GameManager.player.dead:
		GameManager.kill()
		warning_audio.stop()
		control_timer = 0
		
	if item_count == 0:
		item_indicator.material.set_shader_param('intensity', int(GameManager.game_time*30)%2)
		

func reset(init_timer = 0):
	GameManager.out_of_control = false
	warning_audio.stop()
	control_timer = init_timer
	set_swap_threshold(swap_threshold + 2 + swap_threshold_penalty)
	swap_threshold_penalty = 0

func on_GM_swap():
	item_count += 1
	item_indicator.material.set_shader_param('intensity', 0)
	$ItemProgress/Tween.interpolate_property(item_indicator, "value", (item_count - 1)*100, item_count*100, 0.1)
	$ItemProgress/Tween.start()
	if item_count >= 3:
		item_count = 0
		$ItemProgress/Tween.interpolate_property(item_indicator, "value", 300, 0, 0.6)
		$ItemProgress/Tween.start()
		$ItemAudio.play(0)
	
	
func set_swap_threshold(value):
	swap_threshold = clamp(value, 0, max_control_time)
	threshold.value = (swap_threshold / max_control_time)*(thresh_max_value - thresh_min_value) + thresh_min_value
	print(threshold.value)
	print(swap_threshold)
	

func out_of_control():
	GameManager.out_of_control = true
	tint_progress = lerp(tint_progress, colors[randi() % colors.size()], 0.9)
	if beep_timer < 0:
		beep_timer = 0.05 + (max_control_time - control_timer)*0.3/3
		warning_audio.play()
		
func in_control():
	if control_timer < swap_threshold:
		unlocked_last_frame = false
		tint_progress = lerp(tint_progress, Color(0.58,0.1,0.1,1), 0.1)
	else:
		if not unlocked_last_frame:
			unlocked_audio.play()
		
		unlocked_last_frame = true
		var t = control_timer - swap_threshold
		var f = 3 + control_timer / 3
		var flash = pow(0.5 + 0.5*cos(t*f), 4)
		tint_progress = Color(0.58,0.1,0.1,1).linear_interpolate(Color.white, flash)
		


#func _on_ItemAudio_finished():
#	item_count = 0
#	item_indicator.value = item_count
