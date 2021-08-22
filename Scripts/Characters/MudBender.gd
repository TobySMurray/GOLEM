extends "res://Scripts/Enemy.gd"

var enemy = null
var shifting = false

func _ready():
	enemy_type = EnemyType.SHAPESHIFTER
	health = 100
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

func toggle_enhancement(state):
	pass

func _physics_process(delta):
	if enemy:
		enemy.global_position = position
func player_action():
	if Input.is_action_just_pressed("attack1") and not attacking and attack_cooldown < 0:
		print("attacking")
		attack()
	if Input.is_action_just_pressed("attack2") and not attacking and attack_cooldown < 0:
		combo()
	if Input.is_action_just_pressed("attack1") and Input.is_action_just_pressed("attack2") and special_cooldown < 0:
		print("shifting")
		shapeshift()

func combo():
	play_animation('Special')
	attacking = true
	max_speed = 0
	attack_cooldown = max_attack_cooldown

func attack():
	play_animation('Attack')
	attacking = true
	max_speed = 0
	attack_cooldown = max_attack_cooldown
	
func shapeshift():
	attacking = true
	special_cooldown = 0
	if not enemy:
		play_animation('Despawn')
	else:
		despawn_enemy()
		play_animation('Spawn')
	
func toggle_playerhood(state):
	if state == false and enemy:
		shapeshift()
	.toggle_playerhood(state)
	if enemy:
		enemy.toggle_playerhood(state)
	
func spawn_enemy(type):
	if not enemy:
		if type == Enemy.EnemyType.UNKNOWN:
			type = Util.choose_weighted(GameManager.enemy_scenes.keys(), GameManager.level['enemy_weights'])
		enemy = GameManager.enemy_scenes[type].instance().duplicate()
		if self != GameManager.true_player:
			enemy.add_to_group('enemy')
		elif self == GameManager.true_player:
			enemy.add_to_group('player')
		$EnemyContainer.add_child(enemy)
		#self.EV_particles.visible = false
		self.healthbar.visible = false
		self.shape.disabled = true
		$Hitbox/CollisionShape2D.disabled = true
		shifting = true
		enemy.animplayer.play_backwards('Die')
		enemy_type = enemy.enemy_type
		health = enemy.health
		max_speed = enemy.max_speed
		flip_offset = enemy.flip_offset
		
func despawn_enemy():
	enemy.animplayer.play('Die')
	$EnemyContainer.remove_child(enemy)
	enemy = null
	enemy_type = EnemyType.SHAPESHIFTER
	health = 100
	max_speed = 140
	flip_offset = -39

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == 'Attack':
		attacking = false
		max_speed = 140
	if anim_name == 'Special':
		attacking = false
		max_speed = 140
	if anim_name == 'Despawn':
		spawn_enemy(Util.choose_weighted(GameManager.enemy_scenes.keys(), GameManager.level['enemy_weights']))
	if anim_name == 'Spawn':
		attacking = false
		shifting = false
		self.EV_particles.visible = true
		self.healthbar.visible = true
		self.shape.disabled = false
		$Hitbox/CollisionShape2D.disabled = false
	elif anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()
