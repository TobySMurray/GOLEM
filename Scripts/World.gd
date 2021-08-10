extends Node2D

const grid_size = Vector2(60, 40)
const anchor_points = [
	[Vector2(-grid_size.x, -grid_size.y)/2, Vector2(grid_size.x, -grid_size.y)/2, Vector2(-grid_size.x, -grid_size.y)/2],
	[Vector2(-grid_size.x, -grid_size.y)/2, Vector2(grid_size.x, -grid_size.y)/2, Vector2(-grid_size.x, -grid_size.y)/2],
	[Vector2(-grid_size.x, grid_size.y)/2, Vector2(grid_size.x, grid_size.y)/2, Vector2(-grid_size.x, grid_size.y)/2]
]

const levels = ['SkyRuins', 'Labyrinth', 'Desert']
const chunk_names = ['TopLeft', 'TopMid', 'TopRight', 'MidLeft', 'MidMid', 'MidRight', 'BottomLeft', 'BottomMid', 'BottomRight']

const chunk_paths = {
	'SkyRuins': [[[], [], []], [[], [], []], [[],[],[]]],
	'LabyrinthLevel': [[[], [], []], [[], [], []], [[],[],[]]],
	'DesertLevel': [[[], [], []], [[], [], []], [[],[],[]]]
}

onready var chunks_node = $Chunks
onready var objects_node = $Objects

var chunks = [[null, null, null],[null, null, null],[null, null, null]]


func _ready():
	get_chunk_paths()
	populate_level('SkyRuins')

func get_chunk_paths():
	var base_path = 'res://Scenes/Levels/'
	for level in levels:
		
		var x = 0
		var y = 0
		for i in range(9):
			var path = base_path + level + chunk_names[i]
			var files = []
			var dir = Directory.new()
			dir.open(path)
			dir.list_dir_begin()
			
			while true:
				var file = dir.get_next()
				if file == '':
					break
				chunk_paths[level][x][y].append(path + file)
					
			dir.list_dir_end()
			x += 1
			if x > 2:
				x = 0
				y += 1
			
func populate_level(level_name):
	var num_objective_chunks = 3
	var objective_chunks = []
	
	var num_empty_chunks = 1 + round(randf())
	var empty_chunks = []
	
	var slot_positions = [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(2, 0), Vector2(2, 1), Vector2(2, 2)].shuffle()
	for slot in slot_positions:
		var x = int(slot.x)
		var y = int(slot.y)
		var candidate_paths = chunk_paths[level_name][x][y]
	
		if len(candidate_paths) > 0:
			var candidates = []
			for path in candidate_paths:
				candidates.append(load(path).instance())
			
			candidates.shuffle()
			var chosen = null
			
			if len(objective_chunks) < num_objective_chunks:
				for candidate in candidates:
					if candidate.chunk_type == 'OBJECTIVE':
						objective_chunks.append(candidate)
						chosen = candidate

			if not chosen and len(empty_chunks) < num_empty_chunks:
				for candidate in candidates:
					if candidate.chunk_type == 'EMPTY':
						empty_chunks.append(candidate)
						chosen = candidate
						
			if not chosen:
				chosen = candidates[0]
				
			chunks[x][y] = chosen
			chunks_node.add_child(chosen)
			chosen.position = anchor_points[x][y]
			for obj in chosen.get_node('Objects').get_children():
				Util.reparent_to(obj, objects_node)
		
