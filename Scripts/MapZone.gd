tool
extends Node2D

class_name MapZone

const TILE_SIZE = 16
enum ZoneType {SPAWN, NO_TP}

export var rect : Rect2 = Rect2(0, 0, TILE_SIZE, TILE_SIZE) setget set_rect
export (ZoneType) var zone_type = ZoneType.SPAWN setget set_type 

var size : Vector2 = Vector2(TILE_SIZE, TILE_SIZE) setget set_size
var pos : Vector2 = Vector2(TILE_SIZE, TILE_SIZE) setget set_pos

var color = Color.red
var handles = []

func set_rect(value: Rect2):
	value.size.x = max(value.size.x, TILE_SIZE)
	value.size.y = max(value.size.y, TILE_SIZE)
	
	size = value.size
	pos = value.position
	rect = value
	update()

func set_size(value : Vector2):
	size = value
	recalculate_rect()
	
func set_pos(value : Vector2):
	pos = value
	recalculate_rect()
	
func set_type(value : int):
	if value == zone_type or not is_instance_valid(get_parent()):
		return

	var manager = get_parent().get_parent()
	manager.retype_zone(self, value)
	
	zone_type = value
	match zone_type:
		ZoneType.SPAWN:
			color = Color.red
		ZoneType.NO_TP:
			color = Color.cyan
	
	update()
	
func recalculate_rect():
	rect = Rect2(pos, size)
	update()
	
func _draw():
	var edge_color = color
	var fill_color = color
	
	if Engine.editor_hint:
		edge_color.a = 0.7
		fill_color.a = 0.1
	else:
		edge_color.a = 0.5
		fill_color.a = 0.0
		
	draw_rect(rect, fill_color, true)
	draw_rect(rect, edge_color, false)
	
		
	
