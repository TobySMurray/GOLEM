extends Node2D


onready var attack_cooldown = $Attack
onready var special_cooldown = $Special
onready var sprite = $Sprite

var flash_timer = 0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_viewport().warp_mouse(get_global_mouse_position())
	
	
func _process(delta):
	self.position = self.get_global_mouse_position()

	
func _physics_process(delta):
	if flash_timer > 0:
		flash_timer -= delta
		sprite.modulate = Color.black if int(flash_timer*20)%2 == 0 else Color.white
	else:
		sprite.modulate = Color.white 
		
	if is_instance_valid(GameManager.player):
		attack_cooldown.max_value = GameManager.player.max_attack_cooldown
		attack_cooldown.value = GameManager.player.attack_cooldown
		if attack_cooldown.value <= 0:
			if attack_cooldown.visible:
				attack_cooldown.visible = false
				flash_timer = 0.2
		else:
			attack_cooldown.visible = true
			
		special_cooldown.max_value = GameManager.player.max_special_cooldown
		special_cooldown.value = GameManager.player.special_cooldown
		if special_cooldown.value <= 0:
			special_cooldown.visible = false
		else:
			special_cooldown.visible = true
