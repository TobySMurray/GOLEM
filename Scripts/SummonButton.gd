extends Area2D

onready var sprite = $Sprite
onready var hologram = $Hologram

var active = false
var timer = 0

export (Enemy.EnemyType) var enemy

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.connect('on_swap', self, 'on_swap')
	hologram.texture = load(Util.enemy_icon_paths[enemy])
	
func _process(delta):
	timer += delta
	hologram.modulate.a = 0.6 + sin(timer*2)*0.15
		
func _input(ev):
	if active and ev is InputEventKey and ev.pressed and ev.scancode == KEY_E and not ev.echo:
		GameManager.call_deferred('spawn_enemy', enemy, Vector2(randf()*100 - 50, randf()*100 - 50))
		
func on_swap():
	sprite.material.set_shader_param('intensity', 1)
	active = false
	
func _on_SummonButton_body_entered(body):
	if body.is_in_group('player'):
		sprite.material.set_shader_param('intensity', 0)
		active = true
		
func _on_SummonButton_body_exited(body):
	if body.is_in_group('player'):
		sprite.material.set_shader_param('intensity', 1)
		active = false

