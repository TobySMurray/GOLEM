extends Control

onready var timer = $Timer
var time = 2.0

func _ready():
	timer.set_wait_time(time)
		
func show():
	$AnimationPlayer.play("FadeIn")
	timer.start()

func hide():
	$AnimationPlayer.play("FadeOut")
	
func set_upgrade(upgrade):
	print("Displaying upgrade: "+ upgrade)
	$Name.text = Upgrades.upgrades[upgrade]['name']
	$Description.text = Upgrades.upgrades[upgrade]['desc']
	match(Upgrades.upgrades[upgrade]['type']):
		Enemy.EnemyType.SHOTGUN:
			$TextureRect.texture = load('res://Art/Characters/Shotgunner/icon.png')
		Enemy.EnemyType.CHAIN:
			$TextureRect.texture = load('res://Art/Characters/Ball and Chain Bot/icon.png')
		Enemy.EnemyType.WHEEL:
			$TextureRect.texture = load('res://Art/Characters/Bot Wheel/icon.png')
		Enemy.EnemyType.FLAME:
			$TextureRect.texture = load('res://Art/Characters/flamethrower bot/icon.png')
		Enemy.EnemyType.ARCHER:
			$TextureRect.texture = load('res://Art/Characters/Archer/icon.png')
		Enemy.EnemyType.EXTERMINATOR:
			$TextureRect.texture = load('res://Art/Characters/Exterminator/icon.png')
		Enemy.EnemyType.SORCERER:
			$TextureRect.texture = load('res://Art/Characters/Sorcerer Bot/icon.png')
		Enemy.EnemyType.SABER:
			$TextureRect.texture = load('res://Art/Characters/3 Saber dude/icon.png')
		

func _on_Timer_timeout():
	hide()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "FadeOut":
		queue_free()
