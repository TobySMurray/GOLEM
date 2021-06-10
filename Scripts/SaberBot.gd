extends "res://Scripts/Enemy.gd"

onready var SaberRing = load("res://Scenes/SaberRing.tscn")
onready var slash_trigger = $SlashTrigger
onready var slash_collider = $SlashCollider


var walk_speed
var dash_speed
var slash_charges
var kill_mode_cooldown
var saber_ring_durability

var walk_speed_levels = [90, 100, 110, 120, 130, 140, 150]
var dash_speed_levels = [250, 300, 333, 366, 400, 433, 466]
var slash_charges_levels = [1, 1, 1, 2, 2, 3, 3]
var kill_mode_cooldown_levels = [10, 6, 6, 6, 6, 6, 5]
var saber_ring_durability_levels = [0.08, 0.1, 0.133, 0.166, 0.2, 0.233, 0.266]

var saber_ring = null
var sabers_sheathed = true
var waiting_for_saber_recall = false

var in_kill_mode = false
var kill_mode_timer = 0
var remaining_slashes = 0

var rage_color = Color(1, 0, 0.45)

func _ready():
	health = 500
	max_speed = walk_speed
	flip_offset = -16
	healthbar.max_value = health
	max_attack_cooldown = 1
	max_special_cooldown = 0.8
	score = 60
	init_healthbar()
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	dash_speed = dash_speed_levels[level]
	max_speed = walk_speed
	slash_charges = slash_charges_levels[level]
	kill_mode_cooldown = kill_mode_cooldown_levels[level]
	saber_ring_durability = saber_ring_durability_levels[level]
	
func misc_update(delta):
	.misc_update(delta)
	if not sabers_sheathed and not waiting_for_saber_recall and saber_ring.accel <= 0:
		recall_sabers()
	
	if waiting_for_saber_recall and saber_ring.recalled:
		waiting_for_saber_recall = false
		start_sheath()
		
	if in_kill_mode:
		kill_mode_timer -= delta
		if kill_mode_timer < 0:
			end_kill_mode()
			
		#slash_trigger.position.x = -15 if facing_left else 15
	
func player_action():
	.player_action()
	if not attacking and not in_kill_mode and Input.is_action_just_pressed("attack1"):
		if sabers_sheathed:
			start_unsheath()
		else:
			recall_sabers()
			
	if not attacking and special_cooldown < 0 and sabers_sheathed and Input.is_action_just_pressed("attack2"):
		start_kill_mode()
			
	if not sabers_sheathed:
		if waiting_for_saber_recall:
			saber_ring.target_pos = global_position + Vector2(-29 if facing_left else 29, -8)
		else:
			saber_ring.target_pos = get_global_mouse_position()
		
		
func start_kill_mode():
	in_kill_mode = true
	special_cooldown = kill_mode_cooldown
	max_speed = dash_speed
	slash_trigger.get_node("CollisionShape2D").set_deferred("disabled", false)
	remaining_slashes = slash_charges
	sprite.modulate = rage_color
	base_color = rage_color
	kill_mode_timer = 1
	
	if is_in_group("player"):
		GameManager.lerp_to_timescale(0.75)
	
func end_kill_mode():
	if attacking: return
	
	in_kill_mode = false
	max_speed = walk_speed
	slash_trigger.get_node("CollisionShape2D").set_deferred("disabled", true)
	sprite.modulate = Color.white
	base_color = Color.white
	
	if is_in_group("player"):
		GameManager.lerp_to_timescale(1)
	
func slash():
	attacking = true
	kill_mode_timer = 1
	animplayer.play("Special")
	slash_collider.position.x = -10 if facing_left else 10
	melee_attack(slash_collider, 150, 1000, 2)
	
	if is_in_group("player"):
		GameManager.camera.set_trauma(0.6)
		GameManager.timescale = 0.0
		
func end_slash():
	attacking = false
	remaining_slashes -= 1
	if remaining_slashes <= 0:
		end_kill_mode()
			

func start_unsheath():
	lock_aim = true
	attacking = true
	animplayer.play("Unsheath")
	
func recall_sabers():
	lock_aim = true
	attacking = true
	saber_ring.recall()
	waiting_for_saber_recall = true
	
func start_sheath():
	sabers_sheathed = true
	saber_ring.queue_free()
	saber_ring = null
	animplayer.play("Sheath")
	
func on_sabers_sheathed():
	lock_aim = false
	attacking = false
	walk_anim = "Walk"
	idle_anim = "Idle"
	
func on_sabers_unsheathed():
	sabers_sheathed = false
	saber_ring = SaberRing.instance().duplicate()
	get_parent().add_child(saber_ring)
	saber_ring.source = self
	saber_ring.global_position = global_position + Vector2(-29 if facing_left else 29, -8)
	saber_ring.visible = true
	saber_ring.mass = saber_ring_durability
	lock_aim = false
	attacking = false
	walk_anim = "Walk Saberless"
	idle_anim = "Idle Saberless"


func _on_SlashTrigger_area_entered(area):
	if in_kill_mode and not attacking and not area.get_parent() == self and area.is_in_group("hitbox"):
		velocity = (area.global_position - global_position).normalized() * 500
		slash()
