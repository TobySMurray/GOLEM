extends "res://Scripts/Enemy.gd"

onready var death_orb = load("res://Scenes/DeathOrb.tscn")

var orb = null
onready var stand = $JojoReference
onready var attack_collider = $AttackCollider/CollisionShape2D

var walk_speed = 0
var smack_recharge = 0
var smack_speed = 0

var walk_speed_levels = [100, 120, 135, 150, 165]
var smack_recharge_levels = [1.5, 1.2, 1, 0.8, 0.6]
var smack_speed_levels = [250, 300, 333, 366, 400]

var stand_timer = 0
var smack_velocity
var stand_pos = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 180
	score = 100
	flip_offset = -13
	init_healthbar()
	hide_stand()
	toggle_enhancement(false)
	max_special_cooldown = 2
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else 0
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	smack_recharge = smack_recharge_levels[level]
	smack_speed = smack_speed_levels[level]
	max_attack_cooldown = smack_recharge
	
func misc_update(delta):
#	if orb:
#		var pull_vector = get_global_mouse_position() - orb.global_position
#		orb.velocity += pull_vector.normalized()*250*delta
		
	if stand.visible:
		stand.global_position = stand_pos
		
		stand_timer -= delta
		stand.modulate.a = 0.7*sqrt(max(stand_timer, 0))
		
		if stand_timer < 0.9 and smack_velocity.x != 0:
			if orb:
				orb.velocity = smack_velocity
				orb.decel_timer = 0
			smack_velocity = Vector2.ZERO
			
		if stand_timer == 0:
			hide_stand()

func player_action():
	if Input.is_action_just_pressed('attack1') and attack_cooldown < 0:
		attack_cooldown = smack_recharge
		if not orb:
			attacking = true
			animplayer.play("Attack")
		else:
			smack_orb(get_global_mouse_position())

	elif Input.is_action_just_pressed('attack2') and special_cooldown < 0:
		special_cooldown = 2
		attacking = true
		animplayer.play("Special")
		
	
#	if orb:
#		var to_orb = orb.global_position - global_position
#		var zoom = 1 + clamp(max((abs(to_orb.x)-300)/250, (abs(to_orb.y)-100)/250), 0, 1)
#		GameManager.camera.zoom = Vector2(zoom, zoom)
#	else:
#		var zoom = lerp(GameManager.camera.zoom.x, 1, 0.1)
#		GameManager.camera.zoom = Vector2(zoom, zoom)
		
func ai_action():
	aim_direction = (GameManager.player.global_position - global_position)
	
	if attack_cooldown < 0 and not attacking:
		if orb:
			var orb_dist =  (GameManager.player.global_position - orb.global_position).length()
			
			if orb_dist > 500 and special_cooldown < 0:
				special_cooldown = 3
				attacking = true
				animplayer.play("Special")
				
			elif orb_dist > 50:
				attack_cooldown = smack_recharge
				smack_orb(GameManager.player.global_position)
				
		elif aim_direction.length() < 400:
			attack_cooldown = smack_recharge
			attacking = true
			animplayer.play("Attack")
			
			
func launch_orb():
	orb = death_orb.instance().duplicate()
	orb.global_position = global_position + (Vector2(-20, 0) if facing_left else Vector2(20, 0))
	orb.velocity = aim_direction.normalized() * smack_speed
	orb.source = self
	get_node("/root").add_child(orb)
	
	if is_in_group("player"):
		GameManager.camera.set_trauma(0.5)
	
func smack_orb(target_pos):
	var smack_dir = (target_pos - orb.global_position).normalized()
	var side = -sign(smack_dir.x)
	var offset = Vector2(20*side, 0*smack_dir.y)
	conjure_stand(orb.global_position + offset + orb.velocity*0.1, -side)
	smack_velocity = smack_dir*max(smack_speed, orb.velocity.length()*1.1)
	
	if is_in_group("player"):
		GameManager.camera.set_trauma(0.4)
	
func conjure_stand(pos, dir):
	stand_timer = 1
	stand.visible = true
	stand.monitorable = true
	stand.modulate.a = 0.7
	
	var stand_sprite = stand.get_node("AnimatedSprite")
	stand_sprite.frame = 0
	stand_sprite.play("Attack")
	stand_sprite.flip_h = dir < 0
	stand_sprite.offset.x = flip_offset if dir < 0 else 0
	stand.global_position = pos
	stand_pos = pos
	
func area_attack():
	melee_attack(attack_collider, 20, 300, 1)
	if is_in_group("player"):
		GameManager.camera.set_trauma(0.5)
	
func detonate_orb():
	GameManager.camera.offset = Vector2.ZERO
	if orb:
		GameManager.spawn_explosion(orb.global_position + Vector2(0, 10), self, 1.5, 30, 500)
		orb.queue_free()
		orb = null
	
func hide_stand():
	stand.visible = false
	stand.monitorable = false
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Attack" or anim_name == "Special":
		attacking = false
		lock_aim = false
		#max_speed = walk_speed
		
	elif anim_name == "Die":
		detonate_orb()
		actually_die()
