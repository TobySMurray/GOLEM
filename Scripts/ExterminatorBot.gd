extends "res://Scripts/Enemy.gd"

onready var teleport_sprite = $TeleportSprite
onready var deflector_shape = $Deflector/CollisionShape2D

var teleport_start_point = Vector2.ZERO
var teleport_end_point = Vector2.ZERO
var charging_tp = false
var teleport_timer = 0
var walk_speed = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 200
	max_speed = walk_speed
	flip_offset = 24
	healthbar.max_value = health
	init_healthbar()
	score = 100
	
func _process(delta):
	if charging_tp:
		teleport_timer -= delta
		if teleport_timer < 0.1:
			animplayer.play("Appear")
			if teleport_timer < 0:
				teleport()
			
func player_action():
	if Input.is_action_just_pressed("attack1") and attack_cooldown < 0 and not attacking:
		attack()
	if Input.is_action_just_pressed("attack2") and special_cooldown < 0 and not attacking:
		start_teleport()
		
func attack():
	attacking = true
	lock_aim = true
	max_speed = 0
	attack_cooldown = 1.5
	animplayer.play("Attack")
	
func start_teleport():
	charging_tp = true
	attacking = true
	teleport_start_point = global_position
	teleport_end_point = get_global_mouse_position()
	special_cooldown = 1.6
	teleport_timer = 0.4
	lock_aim = true
	max_speed = 0
	sprite.visible = false
	
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
	
func area_deflect():
	melee_attack(deflector_shape, 20, 300, 2)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Appear" or anim_name == "Attack":
		lock_aim = false
		max_speed = walk_speed
		attacking = false
		invincible = false
	elif anim_name == "Die":
		queue_free()


func _on_Deflector_area_entered(area):
	if area.is_in_group("bullet"):
		area.velocity += (area.global_position - global_position).normalized()*area.velocity.length()/2
