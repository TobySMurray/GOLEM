extends Node2D

onready var astar_node = AStar2D.new()
onready var ground_tm = GameManager.ground
onready var obstacles_tm = GameManager.obstacles

export(Vector2) var map_size = Vector2(16, 16)

var map_coordinates_top_left = Vector2(-28, -11)
var map_coordinates_bottom_left = Vector2(-28, 53)
var map_coordinates_top_right = Vector2(118, -11)
var map_coordinates_bottom_right = Vector2(118, 53)
var min_x = -28
var max_x = 118
var min_y = -11
var max_y = 53

var obstacles
var point_path = []


func _ready():
	obstacles = obstacles_tm.get_used_cells()
	var min_x = 100000
	var max_x = 0
	var min_y = 100000
	var max_y = 0
	for point in ground_tm.get_used_cells():
		if point.x < min_x:
			min_x = point.x
		elif point.x > max_x:
			max_x = point.x
		if point.y < min_y:
			min_y = point.y
		elif point.y > max_y:
			max_y = point.y
		
	var walkable_cells = build_walkable_cells_list()
	connect_walkable_cells(walkable_cells)
	

func build_walkable_cells_list():
	var points_array = []
	for y in range(map_coordinates_top_left.y, map_coordinates_bottom_left.y):
		for x in range(map_coordinates_top_left.x, map_coordinates_top_right.x):
			var point = Vector2(x, y)
			if point in obstacles or is_outside_map(point):
				continue
			else:
				points_array.append(point)
				var point_index = calculate_point_index(point)
				astar_node.add_point(point_index, point)
	return points_array
	

func connect_walkable_cells(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		for local_y in range(3):
			for local_x in range(3):
				var point_relative = Vector2(point.x + local_x - 1, point.y + local_y - 1)
				var point_relative_index = calculate_point_index(point_relative)
				
				# check if point is out of the map
				if point_relative == point:
					continue
					
				# check if the point isn't in the astar node (i.e. it's an obstacle)
				if not astar_node.has_point(point_relative_index):
					continue
				astar_node.connect_points(point_index, point_relative_index, true)
					
					
func is_outside_map(point):
	return !(point in ground_tm.get_used_cells())
	
	
func calculate_point_index(point):
	return (point.x + abs(min_x)) + (abs((map_coordinates_top_left.x)) + abs(map_coordinates_top_right.x)) * (point.y + abs(min_y))


func find_path(global_start, global_end):
	
	var start = ground_tm.world_to_map(global_start)
	var end = ground_tm.world_to_map(global_end)
	
	var start_index = calculate_point_index(start)
	var end_index = calculate_point_index(end)
	
	if not astar_node.has_point(start_index) or not astar_node.has_point(end_index):
		return []
	
	var tile_path = astar_node.get_point_path(start_index, end_index)
	
	var world_path = []
	for point in tile_path:
		world_path.append(ground_tm.map_to_world(point))

	return world_path

func get_astar_target_velocity(my_position, target):
	var path = find_path(my_position, target)
	var target_position
	if len(path) == 0:
		target_position = my_position
	else:
		if GameManager.ground.world_to_map(path[0]) == GameManager.ground.world_to_map(my_position):
			if len(path) == 1:
				target_position = path[0]
			else:
				target_position = path[1]
		else:
			target_position = path[0]
			
	var target_velocity = target_position - my_position
	return target_velocity
