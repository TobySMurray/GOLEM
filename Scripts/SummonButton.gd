extends Host

onready var sprite = $Sprite
onready var hologram = $Hologram

var active = false
var timer = 0

export (Enemy.EnemyType) var enemy

# Called when the node enters the scene tree for the first time.
func _ready():
	uses_swap_bar = false
	override_swap_camera = true
	hologram.texture = load(Util.enemy_icon_paths[enemy])
	
func _process(delta):
	timer += delta
	hologram.modulate.a = 0.6 + sin(timer*2)*0.15
	
func _physics_process(delta):
	if is_player:
		GameManager.camera.lerp_zoom(2)
		if Input.is_action_just_pressed('attack1'):
			GameManager.spawn_enemy(enemy, get_global_mouse_position())
		
func toggle_playerhood(state):
	.toggle_playerhood(state)
	sprite.material.set_shader_param('intensity', 0 if state else 1)
		
