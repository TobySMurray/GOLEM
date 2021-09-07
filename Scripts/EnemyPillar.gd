extends StaticBody2D

signal on_death

export (Enemy.EnemyType) var enemy_type = Enemy.EnemyType.UNKNOWN
var enemy = null

var has_appeared = false
var appear_timer = 1.0

var health = 300
var invincible = false
var velocity = Vector2.ZERO
var mass  = 999

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	
func _physics_process(delta):
	appear_timer -= delta
	if not has_appeared:
		if appear_timer < 0:
			has_appeared = true
			visible = true
			if enemy_type == Enemy.EnemyType.UNKNOWN:
				enemy_type = Util.choose_weighted(GameManager.enemy_scenes.keys(), GameManager.level['enemy_weights'])

			spawn_enemy(enemy_type)
	elif appear_timer > -0.7:
		scale.y = min(1, 0.1 + 0.9*(-2*appear_timer))
		
	if is_instance_valid(enemy):
		enemy.attack_cooldown += delta/2
	
func spawn_enemy(type = Enemy.EnemyType.UNKNOWN):
	if type == Enemy.EnemyType.UNKNOWN:
		type = Util.choose_weighted(GameManager.enemy_scenes.keys(), GameManager.level['enemy_weights'])
	enemy = GameManager.enemy_scenes[type].instance().duplicate()
	enemy.immobile = true
	enemy.invincible = true
	enemy.attack_cooldown = 1.0
	enemy.shoot_through = [self]
	enemy.get_node('EnemyFX/HealthBar').visible = false
	enemy.add_swap_shield(1)
	enemy.add_to_group('enemy')
	$EnemyContainer.add_child(enemy)
	
func take_damage(damage, source, stun = 0):
	if health > 0:
		health -= damage
		if health <= 0:
			call_deferred('die')

func die():
	if is_instance_valid(enemy):
		enemy.immobile = false
		enemy.swap_shield_health = 0
		enemy.update_swap_shield()
		enemy.shoot_through = []
		enemy.healthbar.visible = true
		Util.reparent_to(enemy, get_parent())
		enemy.global_position = global_position - enemy.foot_offset
		enemy.invincible = false
		enemy.invincibility_timer = 0.7
	emit_signal('on_death', enemy)
	queue_free()
