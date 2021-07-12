extends Enemy

export var current_level = 0
onready var world_map = $WorldMap
onready var load_triggers = [$WorldMap/SkyRuins, $WorldMap/Labyrinth, $WorldMap/Desert, $WorldMap/Summit]

func _ready():
	GameManager.swappable = true
	
func _physics_process(delta):
		world_map.modulate.a = min(pow((GameManager.camera.zoom.x - 1.0)/15, 0.5), 1.0)
		
func toggle_swap(state):
	.toggle_swap(state)
	for i in range(len(load_triggers)):
		load_triggers[i].set_accessible(state and i != current_level)
	

func choose_swap_target():
	swap_cursor.global_position = get_global_mouse_position()
	
	var swapbar = GameManager.swap_bar
	GameManager.camera.lerp_zoom(20, 0.4, 0.035 + 0.06*(GameManager.camera.zoom.x - 1.0)/19)
	
	#world_map.modulate.a = lerp(world_map.modulate.a, min(world_map.modulate.a + 0.1, 1.0) , 0.15)
	
	if Input.is_action_just_released("swap"):
		if is_instance_valid(swap_cursor.selected_enemy):
			swap_cursor.selected_enemy.toggle_playerhood(true)
			
		if is_instance_valid(swap_cursor.selected_enemy) or !dead:
			toggle_swap(false)
	else:
		draw_transcender()
