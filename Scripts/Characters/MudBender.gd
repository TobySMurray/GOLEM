extends "res://Scripts/Enemy.gd"

onready var attack_collider = $AttackCollider/CollisionShape2D

var enemy = null
var shifting = false
var shift_timer = 0

func _ready():
	enemy_type = EnemyType.SHAPESHIFTER
	max_health = 100
	max_speed = 140
	flip_offset = -39
	max_attack_cooldown = 1
	attack_cooldown = 0
	max_special_cooldown = 5
	special_cooldown = 0
	healthbar.max_value = health
	init_healthbar()
	score = 50
	toggle_enhancement(false)

#func toggle_enhancement(state):
#	pass
	
func misc_update(delta):
	if is_instance_valid(enemy):
		global_position = enemy.global_position
		invincibility_timer = 0.7
		
		shift_timer -= delta
		if shift_timer < 0:
			despawn_enemy()
			
		
func player_action():
	if Input.is_action_just_pressed("attack1") and not attacking and attack_cooldown < 0:
		start_attack()
	if Input.is_action_just_pressed("attack2") and not is_instance_valid(enemy) and not attacking and attack_cooldown < 0:
		attacking = true
		play_animation('Despawn')

func mud_slap():
	play_animation('Special')
	attacking = true
	max_speed = 0
	attack_cooldown = max_attack_cooldown

func start_attack():
	play_animation('Attack')
	attacking = true
	#max_speed = 0
	attack_cooldown = max_attack_cooldown
	
func attack():
	attack_collider.position.x = -15 if facing_left else 15
	velocity += aim_direction.normalized()*250
	Violence.melee_attack(self, attack_collider, 50, 500, 1)
	
	
func toggle_playerhood(state):
#	if state == false and is_instance_valid(enemy):
#		despawn_enemy()
#	elif state == true and is_instance_valid(enemy):
	if is_instance_valid(enemy):
		enemy.toggle_playerhood(state)
	.toggle_playerhood(state)
	
func spawn_enemy(type = Enemy.EnemyType.UNKNOWN):
	if not is_instance_valid(enemy):
		special_cooldown = 0
		
		visible = false
		#self.shape.disabled = true
		#$Hitbox/CollisionShape2D.disabled = true
		#enemy.animplayer.play_backwards('Die')
		invincible = true
		invincibility_timer = 0.7
		if type == Enemy.EnemyType.UNKNOWN:
			type = Util.choose_weighted(GameManager.enemy_scenes.keys(), GameManager.level['enemy_weights'])
			
		
#		if self != GameManager.true_player:
#			enemy.add_to_group('enemy')
#		else:
#			enemy.add_to_group('player')
			
		#$EnemyContainer.add_child(enemy)
		enemy = GameManager.enemy_scenes[type].instance().duplicate()
		enemy.can_be_swapped_to = false
		get_parent().add_child(enemy)
		enemy.global_position = global_position
		enemy.toggle_playerhood(GameManager.true_player == self)
		
		shift_timer = 3
#		enemy_type = enemy.enemy_type
#		health = enemy.health
#		max_speed = enemy.max_speed
#		flip_offset = enemy.flip_offset
		
func despawn_enemy():
#	enemy.remove_from_group('player')
#	enemy.add_to_group('enemy')
	enemy.toggle_playerhood(false)
	global_position = enemy.global_position
	enemy.die()
	#enemy.queue_free()?
	enemy = null
	visible = true
	override_speed = 0
	play_animation('Spawn')
	
#	enemy_type = EnemyType.SHAPESHIFTER
#	health = 100
#	max_speed = 140
#	flip_offset = -39

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == 'Attack':
		attacking = false
		max_speed = 140
	if anim_name == 'Special':
		attacking = false
		max_speed = 140
	if anim_name == 'Despawn':
		spawn_enemy()
	if anim_name == 'Spawn':
		override_speed = null
		attacking = false
		shifting = false
		#invincible = false
		#shape.set_deferred('disabled', false)
		#$Hitbox/CollisionShape2D.set_deferred('disabled', false)
	
	elif anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()
