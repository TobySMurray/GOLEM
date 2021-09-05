extends Node2D


onready var attack_cooldown = $Attack
onready var special_cooldown = $Special
onready var sprite = $Sprite

export (NodePath) var subreticle_path
onready var subreticle = get_node(subreticle_path)
var flash_timer = 0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_viewport().warp_mouse(get_global_mouse_position())
	
func _process(delta):
	position = get_global_mouse_position()
	if is_instance_valid(GameManager.true_player):
		subreticle.visible = true
		var player = GameManager.true_player
		var origin = player
		
		if player.is_in_group('enemy'):
			if player.enemy_type == Enemy.EnemyType.SORCERER:
				if is_instance_valid(player.orbs[0]):
					if player.num_orbs == 1:
						origin = player.orbs[0]
					else:
						subreticle.visible = false
						
			elif player.enemy_type == Enemy.EnemyType.SABER:
				if is_instance_valid(player.saber_rings[0]):
					origin = player.saber_rings[0]
					
		subreticle.position = (origin.get_global_transform_with_canvas().origin + global_position)/2
	else:
		subreticle.visible = false

	
func _physics_process(delta):
	if flash_timer > 0:
		flash_timer -= delta
		sprite.modulate = Color.black if int(flash_timer*20)%2 == 0 else Color.white
	else:
		sprite.modulate = Color.white 
		
	if is_instance_valid(GameManager.true_player) and GameManager.true_player.is_in_group('enemy'):
		attack_cooldown.max_value = GameManager.true_player.max_attack_cooldown
		attack_cooldown.value = GameManager.true_player.attack_cooldown
		if attack_cooldown.value <= 0:
			if attack_cooldown.visible:
				attack_cooldown.visible = false
				flash_timer = 0.2
				#GameManager.attack_cooldown_SFX.play()
		else:
			attack_cooldown.visible = true
			
		special_cooldown.max_value = GameManager.true_player.max_special_cooldown
		special_cooldown.value = GameManager.true_player.special_cooldown
		if special_cooldown.value <= 0:
			special_cooldown.visible = false
			#GameManager.special_cooldown_SFX.play()
		else:
			special_cooldown.visible = true
	else:
		attack_cooldown.visible = false
		special_cooldown.visible = false
