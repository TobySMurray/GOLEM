extends "res://Scripts/Enemy.gd"

onready var teleport_sprite = $TeleportSprite
onready var deflector_shape = $Deflector/CollisionShape2D
onready var deflector_visual = $Deflector/DeflectorVisual

var walk_speed
var deflect_power
var shield_power
var deflect_cooldown

var walk_speed_levels = [40, 50, 60, 65, 70, 75, 80]
var deflect_power_levels = [3, 3, 4, 5, 6, 8, 10]
var shield_power_levels = [1200, 400, 500, 600, 700, 800, 900]
var deflect_cooldown_levels = [1.5, 1.5, 1.3, 1.1, 0.9, 0.7, 0.5]

var shield_active = true
var shield_angle = 0

var teleport_start_point = Vector2.ZERO
var teleport_end_point = Vector2.ZERO
var charging_tp = false
var teleport_timer = 0

var nearby_bullets = []
var nearby_death_orbs = []


# Called when the node enters the scene tree for the first time.
func _ready():
	health = 150
	max_speed = walk_speed
	max_attack_cooldown = 1.5
	max_special_cooldown = 1.6
	flip_offset = 24
	healthbar.max_value = health
	init_healthbar()
	score = 100
	swap_cursor.visible = true
	toggle_enhancement(false)
	
func toggle_enhancement(state):
	.toggle_enhancement(state)
	var level = int(GameManager.evolution_level) if state == true else enemy_evolution_level
	
	walk_speed = walk_speed_levels[level]
	max_speed = walk_speed
	deflect_power = deflect_power_levels[level]
	shield_power = shield_power_levels[level]
	deflect_cooldown = deflect_cooldown_levels[level]


func misc_update(delta):
	deflector_visual.rotation = shield_angle
	
	if shield_active:
		for b in nearby_bullets + nearby_death_orbs:
			var bullet_speed = b.velocity.length()
			
			if bullet_speed > 0:
				var angle = (b.global_position - global_position).angle() - shield_angle
				if angle > PI:
					angle -= 2*PI
				elif angle < -PI:
					angle += 2*PI
					
				if abs(angle) < PI/4:
					b.velocity -= (b.velocity/bullet_speed) * min(bullet_speed, shield_power*delta)
				
			else:
				b.source = self
				b.position += velocity*delta
				b.lifetime = 3
				
		#for o in nearby_death_orbs:
		#	o.velocity *= 0.9

	
	if charging_tp:
		teleport_timer -= delta
		if teleport_timer < 0.1:
			animplayer.play("Appear")
			if teleport_timer < 0:
				teleport()


func player_action():
	shield_angle = aim_direction.angle()
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0 and not attacking:
		attack()
	
	if Input.is_action_pressed("attack2"):
		GameManager.camera.lerp_zoom(2)
	else:
		GameManager.camera.lerp_zoom(1)
		
	if Input.is_action_just_released("attack2") and special_cooldown < 0 and not attacking:
		start_teleport(get_global_mouse_position())

func ai_move():
	if randf() < 0.01:
		if randf() < 0.5 or target_velocity == Vector2.ZERO:
			target_velocity = Vector2(randf(), randf())
		else:
			target_velocity = Vector2.ZERO
	else:
		var player_pos = GameManager.player.shape.global_position
		var to_player = player_pos - shape.global_position
		var dist = to_player.length()
		if dist > 200:
			target_velocity = astar.get_astar_target_velocity(shape.global_position, player_pos)

func ai_action():
	aim_direction = GameManager.player.global_position - global_position
	
	var delta_angle = Util.signed_wrap(aim_direction.angle() - shield_angle)
	shield_angle = Util.signed_wrap(shield_angle + sign(delta_angle)/60)
	
	if randf() < 0.002 * len(nearby_bullets) and attack_cooldown < 0:
		attack_cooldown = 2
		attack()
		
	if len(nearby_bullets) < 3 and randf() < 0.002 and special_cooldown < 0:
		for i in range(len(GameManager.player_bullets) > 0):
			bullet = GameManager.player_bullets[int(randf()*len(GameManager.player_bullets))]
			var point = bullet.global_position + bullet.velocity

			if(GameManager.is_point_in_bounds(point)):
				start_teleport(point)
				special_cooldown = 8
				break
				
	elif special_cooldown < 0 and aim_direction.length() < 30:
		special_cooldown = 8
		var point = GameManager.random_map_point()
		if point:
			start_teleport(point)
		
		
func attack():
	attacking = true
	lock_aim = true
	shield_active = false
	deflector_visual.visible = false
	max_speed = 0
	attack_cooldown = deflect_cooldown
	animplayer.play("Attack")
	
func start_teleport(point):
	teleport_end_point = point
	if GameManager.is_point_in_bounds(point + foot_offset):
		charging_tp = true
		attacking = true
		shield_active = false
		deflector_visual.visible = false
		teleport_start_point = global_position
		
		special_cooldown = 1.6
		teleport_timer = 0.4
		lock_aim = true
		max_speed = 0
		sprite.visible = false
		
		expel_bullets(true)
		
		teleport_sprite.global_position = teleport_start_point
		teleport_sprite.frame = 0
		teleport_sprite.play("Vanish")
	
func teleport():
	charging_tp = false
	global_position = teleport_end_point
	teleport_sprite.global_position = teleport_start_point
	animplayer.play("Appear")
	sprite.visible = true
	invincible = true
	
func expel_bullets(radial = false):
	var target_pos = get_global_mouse_position() if is_in_group("player") else GameManager.player.global_position
	for o in nearby_death_orbs:
		o.modulate = Color(0.7, 0.2, 1)
		
	for b in nearby_bullets + nearby_death_orbs:
		b.source = self
		b.lifetime = 5
		
		if radial:
			b.velocity = (b.global_position - global_position).normalized() * deflect_power*100
		else:
			b.velocity = (target_pos - b.global_position).rotated((randf()-0.5)*deg2rad(len(nearby_bullets))).normalized() * deflect_power*100
	
	nearby_bullets = []
		
	
func area_deflect(deflect_pow = deflect_power):
	if is_in_group("player"):
		GameManager.camera.set_trauma(0.5, 5)
		
	melee_attack(deflector_shape, 20, 300, deflect_pow)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Appear" or anim_name == "Attack":
		lock_aim = false
		max_speed = walk_speed
		attacking = false
		shield_active = true
		deflector_visual.visible = true
		invincible = false
		
	elif anim_name == "Die":
		actually_die()


func _on_Deflector_area_entered(area):
	if area.is_in_group("bullet"):
		nearby_bullets.append(area)
		area.lifetime = max(area.lifetime, 5)
	elif area.is_in_group("death orb"):
		nearby_death_orbs.append(area.get_parent())
		
func _on_Deflector_area_exited(area):
	if area.is_in_group("bullet"):
		nearby_bullets.erase(area)
		if area.velocity.x == 0 and area.velocity.y == 0:
			area.despawn()
	elif area.is_in_group("death orb"):
		nearby_death_orbs.erase(area.get_parent())


func _on_Timer_timeout():
	invincible = false



