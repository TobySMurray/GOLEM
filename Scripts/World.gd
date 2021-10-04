extends Node2D

const grid_size = Vector2(60*16, 40*16)
const anchor_points = [
	[Vector2(-grid_size.x, -grid_size.y)/2, Vector2(grid_size.x, -grid_size.y)/2, Vector2(grid_size.x, -grid_size.y)/2],
	[Vector2(-grid_size.x, -grid_size.y)/2, Vector2(grid_size.x, -grid_size.y)/2, Vector2(grid_size.x, -grid_size.y)/2],
	[Vector2(-grid_size.x, grid_size.y)/2, Vector2(grid_size.x, grid_size.y)/2, Vector2(grid_size.x, grid_size.y)/2]
]

const levels = ['SkyRuins', 'Labyrinth', 'Desert']
const chunk_names = ['TopLeft', 'TopMid', 'TopRight', 'MidLeft', 'MidMid', 'MidRight', 'BottomLeft', 'BottomMid', 'BottomRight']

const chunk_paths = {
	'SkyRuins': [[[], [], []], [[], [], []], [[],[],[]]],
	'Labyrinth': [[[], [], []], [[], [], []], [[],[],[]]],
	'Desert': [[[], [], []], [[], [], []], [[],[],[]]]
}

onready var background = $Background
onready var chunks_node = $Chunks
onready var objects_node = $Objects
onready var camera = $Camera
onready var transcender = $Transcender
onready var blood_moon = $BloodMoon 
onready var fog = $Fog
onready var fullbright_light = $FullbrightLight
onready var halfbright_light = $HalfbrightLight
onready var canvas_modulate = $CanvasModulate

var spawn_zones = {
	Enemy.EnemyType.SHOTGUN: [],
	Enemy.EnemyType.CHAIN: [],
	Enemy.EnemyType.FLAME: [],
	Enemy.EnemyType.WHEEL: [],
	Enemy.EnemyType.ARCHER: [],
	Enemy.EnemyType.EXTERMINATOR: [],
	Enemy.EnemyType.SORCERER: [],
	Enemy.EnemyType.SABER: [],
}

var chunks = [[null, null, null],[null, null, null],[null, null, null]]
var fixed_map = null

var init_player = null
var boss = null


func _ready():
	get_chunk_paths()
	GameManager.on_world_loaded(self)
	

func load_level(level_name, fixed_map_path = null):
	clear_level()
	var level = Levels.level_data[level_name]
	
	for k in spawn_zones.keys(): 
		spawn_zones[k] = []
	
	if fixed_map_path:
		print(fixed_map_path)
		fixed_map = load(fixed_map_path).instance()
		chunks_node.add_child(fixed_map)
		fixed_map.position = Vector2.ZERO
		
		init_player = fixed_map.get_node(fixed_map.init_player)
		
		flatten_and_reparent_to_objects(fixed_map.get_node('WorldObjects').get_children())
		if fixed_map.get_node_or_null('MapZoneManager'):
			import_zones(fixed_map.get_node('MapZoneManager'))
		
	else:
		populate_level(level_name)
		
	canvas_modulate.color = level['modulate'] if ('modulate' in level) else Color(1, 1, 1)
	fullbright_light.visible = level['dark']
	halfbright_light.visible = level['dark']
	
	if 'fog' in level:
		fog.visible = true
		fog.material = load('res://Shaders/' + level['fog'] + '.tres')
	else:
		fog.visible = false
		
	GameManager.start_level()
		
	
func clear_level():
	init_player = null
	boss = null
	
	if fixed_map:
		fixed_map.queue_free()
		fixed_map = null
		
	for y in range(3):
		for x in range(3):
			if chunks[x][y]:
				chunks[x][y].queue_free()
				chunks[x][y] = null
				
	for obj in objects_node.get_children():
		obj.queue_free()
		
		
func populate_level(level_name):
	var level = Levels.level_data[level_name]
	
	var need_boss_chunk = true
	
	var objective_chunk_quota = level['objective_chunk_count'][randi() % level['objective_chunk_count'].size()]
	var objective_chunks = []
	
	var empty_chunk_quota = level['empty_chunk_count'][randi() % level['empty_chunk_count'].size()]
	var empty_chunks = []
	
	var slot_positions = [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(2, 0), Vector2(2, 1), Vector2(2, 2)]
	slot_positions.shuffle()
	for slot in slot_positions:
		var x = int(slot.x)
		var y = int(slot.y)
		var candidate_paths = chunk_paths[level_name][y][x]
	
		if len(candidate_paths) > 0:
			var candidates = []
			for path in candidate_paths:
				print('### ' + path)
				candidates.append(load(path).instance())
			
			candidates.shuffle()
			var chosen = null
			
			if not init_player:
				for candidate in candidates:
					if candidate.get('chunk_type') and candidate.chunk_type == Chunk.ChunkType.SPAWN:
						init_player = candidate.get_node(candidate.init_player)
						chosen = candidate
						print('FOUND INIT PLAYER')
						break
						
			if not chosen and not boss:
				for candidate in candidates:
					if candidate.get('chunk_type') and candidate.chunk_type == Chunk.ChunkType.BOSS:
						boss = candidate.get_node(candidate.boss)
						chosen = candidate
						break
			
			if not chosen and len(objective_chunks) < objective_chunk_quota:
				for candidate in candidates:
					if candidate.get('chunk_type') and candidate.chunk_type == Chunk.ChunkType.OBJECTIVE:
						objective_chunks.append(candidate)
						chosen = candidate
						break

			if not chosen and not chosen and len(empty_chunks) < empty_chunk_quota:
				for candidate in candidates:
					if candidate.get('chunk_type') and candidate.chunk_type == Chunk.ChunkType.EMPTY:
						empty_chunks.append(candidate)
						chosen = candidate
						break
						
			if not chosen:
				chosen = candidates[0]
				
			chunks[y][x] = chosen
			chunks_node.add_child(chosen)
			chosen.position = anchor_points[y][x]
			var chunk_objects = chosen.get_node_or_null('Objects')
			if chunk_objects:
				for obj in chosen.get_node('Objects').get_children():
					Util.reparent_to(obj, objects_node)
					
	if not init_player:
		init_player = GameManager.spawn_enemy('shotgun', Vector2.ZERO)
		init_player.toggle_playerhood(true)
		
				
func flatten_and_reparent_to_objects(nodes):
	for node in nodes:
		if node is YSort:
			flatten_and_reparent_to_objects(node.get_children())
		else:
			Util.reparent_to(node, objects_node)
			
func import_zones(MZM: MapZoneManager):
	MZM.visible = false
	for spawn_zone in MZM.get_children():
		for enemy_type in spawn_zones.keys():
			if spawn_zone.can_spawn_enemy(enemy_type):
				spawn_zones[enemy_type].append(spawn_zone.rect)
			
func get_chunk_paths():
	var base_path = 'res://Scenes/Levels/'
	for level in levels:
		
		var x = 0
		var y = 0
		for i in range(9):
			var path = base_path + level + '/' + chunk_names[i]
			#print(path)
			var files = []
			var dir = Directory.new()

			if dir.open(path) == OK:
				dir.list_dir_begin()
				
				while true:
					var file = dir.get_next()
					if file == '':
						break
						
					if file[0] != '.':
						chunk_paths[level][y][x].append(path + '/' + file)
						#print(chunk_paths[level][y][x])
						
				dir.list_dir_end()
			else:
				pass
				#print('ERROR')
				
			x += 1
			if x > 2:
				x = 0
				y += 1
		
