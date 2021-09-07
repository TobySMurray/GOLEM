extends Enemylike

export var current_level = 0
onready var world_map = $WorldMap
onready var load_triggers = [$WorldMap/SkyRuins, $WorldMap/Labyrinth, $WorldMap/Desert, $WorldMap/Summit]

func _ready():
	uses_swap_bar = false
	override_swap_camera= true
	
func _physics_process(delta):
	if is_player:
		if GameManager.swapping:
			GameManager.camera.lerp_zoom(20, 0.4, 0.035 + 0.06*(GameManager.camera.zoom.x - 1.0)/19)
		world_map.modulate.a = min(pow((GameManager.camera.zoom.x - 1.0)/15, 0.5), 1.0)
		
	
