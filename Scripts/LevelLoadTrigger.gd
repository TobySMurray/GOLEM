extends Host
export var destination = 'Labyrinth1'
export (String) var fixed_map = null
export var accessible = true

func _ready():
	set_accessible(accessible)

func set_accessible(state):
	can_be_swapped_to = state
	modulate = Color.white if state else Color.gray
	#collision_layer = 4 if state else 0
	
func toggle_playerhood(state):
	.toggle_playerhood(state)
	GameManager.load_level(destination, fixed_map)

