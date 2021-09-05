extends TextureProgress

onready var threshold = $Threshold
onready var warning_audio = $WarningAudio
onready var unlocked_audio = $UnlockedAudio
onready var rising_audio = $RisingAudio
onready var sparks = $Sparks
#onready var warning_audio = preload("res://Sounds/SoundEffects/warning.wav")
#onready var ready_audio = preload("res://Sounds/SoundEffects/moonready.wav")
#onready var rising_audio = preload('res://Sounds/SoundEffects/ElectricNoiseLoop.wav')

onready var item_indicator = $ItemProgress
onready var Static = $Static

onready var mania_marker = $ManiaMarker

onready var patience_markers = [$PatienceMarker1, $PatienceMarker2]
var patience_upgrades_given = 0

onready var revelry_marker = $RevelryMarker

var enabled = true
var increase_rate = 1.0
var init_control_timer = 0.0
var max_control_time = 20.0
var init_swap_threshold = 1

var bar_min_value = 86
var bar_max_value = 925
var thresh_min_value = 112
var thresh_max_value = 910 

export var control_timer = 0.0 setget set_control_timer
var prev_control_timer = 0.0
var swap_threshold = 0.0
var threshold_death_penalty = 0
var unlocked_last_frame = false
var beep_timer = 0

var item_count = 0

var colors = [Color(1,0.8,0.8,1),Color(1,0.5,0.5,1), Color(1,1,1,1)]

func _ready():
	control_timer = 0
	item_indicator.value = item_count * 100
	set_swap_threshold(init_swap_threshold)
	GameManager.swap_bar = self
	GameManager.connect("on_swap", self, "on_GM_swap")
	
func update_modifiers():
	if GameManager.player_upgrades['mania'] > 0:
		mania_marker.visible = true
		init_control_timer = 5.0
	else:
		mania_marker.visible = false
		init_control_timer = 0.0
		
	if GameManager.player_upgrades['scorn'] > 0:
		swap_threshold = 0
	
	for marker in patience_markers:
		marker.visible = GameManager.player_upgrades['patience'] > 0
	
	revelry_marker.visible = GameManager.player_upgrades['revelry'] > 0
	
	
	
	
func _physics_process(delta):
	if enabled:
		modulate = Color.white

		if control_timer < max_control_time:
			increase_rate = 1.0
			if GameManager.fighting_boss:
				increase_rate *= 0.66
			if GameManager.controlling_boss:
				increase_rate = 2.0
				
			if GameManager.player_upgrades['patience'] > 0:
				increase_rate *= 0.75
			
			set_control_timer(min(control_timer + delta*increase_rate, max_control_time))
			beep_timer -= 0.016
			sparks.speed_scale = 1.0/max(GameManager.timescale, 0.01)
			
			if GameManager.true_player: #and not GameManager.true_player.dead:
				GameManager.can_swap = control_timer > swap_threshold
				
			if GameManager.player_upgrades['patience'] > 0:
				if control_timer >= 10:
					patience_markers[0].modulate = Color(1, 0.85, 0).linear_interpolate(Color.white, pow(0.5 + 0.5*cos(GameManager.level_time*5), 4))
					if patience_upgrades_given == 0:
						patience_upgrades_given += 1
						item_count += 1
						update_item_indicator()
						
					if control_timer >= 17:
						patience_markers[1].modulate = Color(1, 0.85, 0).linear_interpolate(Color.white, pow(0.5 + 0.5*cos(GameManager.level_time*5), 4))
						if patience_upgrades_given < 2:
							patience_upgrades_given += 1
							item_count += 1
							update_item_indicator()
				
			if GameManager.player_upgrades['revelry'] > 0:
				if control_timer >= 15:
					revelry_marker.modulate = Color(1, 0, 0.5).linear_interpolate(Color.white, pow(0.5 + 0.5*cos(GameManager.level_time*5), 4))
					if GameManager.true_player and not GameManager.true_player.berserk:
						GameManager.true_player.toggle_enhancement(true) #Refresh enhancements to activate berserkw
				else:
					revelry_marker.modulate = Color(0.4, 0, 0.2)
				
			if control_timer < max_control_time - 3:
				in_control()
				Static.modulate.a = 0
				
			elif control_timer < max_control_time - 0.1:
				Static.modulate.a = 1 - (max_control_time - control_timer)/3
				out_of_control()
				
			elif GameManager.true_player and not GameManager.player.dead:
				GameManager.on_swap_bar_filled()
				warning_audio.stop()
				control_timer = max_control_time
				
		elif GameManager.true_player.    last_stand:
			set_swap_threshold(swap_threshold + delta/2)
			if swap_threshold >= 20:
				GameManager.true_player.die()
				
	else:
		modulate = Color(1, 1, 1, 0.2)
		GameManager.can_swap = true
		control_timer = 0
		swap_threshold = 0
		
	if item_count == 0:
		item_indicator.material.set_shader_param('intensity', int(GameManager.game_time*30)%2)
		

func reset(init_timer = init_control_timer):
	GameManager.out_of_control = false
	warning_audio.stop()
	control_timer = init_timer
	patience_upgrades_given = 0
	
	var threshold_swap_penalty = 2 if enabled else 0
	if GameManager.player_upgrades['mania'] > 0:
		threshold_swap_penalty *= 0.75
	if GameManager.player_upgrades['patience'] > 0:
		threshold_swap_penalty *= 1.33
	if GameManager.player_upgrades['scorn'] > 0:
		threshold_swap_penalty = 0
		threshold_death_penalty = 0
	
	set_swap_threshold(swap_threshold + threshold_swap_penalty + threshold_death_penalty)
	threshold_death_penalty = 0

func on_GM_swap():
	if GameManager.true_player.is_in_group('enemylike') and GameManager.player_upgrades['patience'] == 0:
		item_count += 1
		update_item_indicator()
	
func update_item_indicator():
	item_indicator.material.set_shader_param('intensity', 0)
	$ItemProgress/Tween.interpolate_property(item_indicator, "value", (item_count - 1)*100, item_count*100, 0.1)
	$ItemProgress/Tween.start()
	if item_count >= 3:
		var enemy_type = GameManager.true_player.enemy_type if GameManager.true_player.is_in_group('enemy') else Enemy.EnemyType.UNKNOWN
		GameManager.give_player_random_upgrade(enemy_type)
			
		item_count = 0
		$ItemProgress/Tween.interpolate_property(item_indicator, "value", 300, 0, 0.6)
		$ItemProgress/Tween.start()
		$ItemAudio.play(0)
	
func set_swap_threshold(value):
	swap_threshold = clamp(value, 0, max_control_time)
	threshold.value = (swap_threshold / max_control_time)*(thresh_max_value - thresh_min_value) + thresh_min_value
	sparks.position.x = 50 + swap_threshold/max_control_time*504
	
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
		
func set_control_timer(val):
	prev_control_timer = control_timer
	control_timer = val
	self.value = (control_timer / max_control_time)*(bar_max_value - bar_min_value) + bar_min_value
		


#func _on_ItemAudio_finished():
#	item_count = 0
#	item_indicator.value = item_count
