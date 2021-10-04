tool
extends EditorPlugin

enum CORNERS {TL, TR, BL, BR}

const map_zone_scene = preload('res://Scenes/MapZone.tscn')
const handle_size = 10.0

var MZM : MapZoneManager
var scene = null

var inspected_zone = null
var dragged_zone = null
var dragged_handle = null
var dragged_handle_corner = CORNERS.TL
var dragged_zone_offset = Vector2.ZERO


func edit(object):
	if object is MapZoneManager:
		print("attempting to select MapZoneManager")
		MZM = object as MapZoneManager
		
	elif object is MapZone:
		print("attempting to select MapZOne")
		MZM = object.get_parent() as MapZoneManager
		
	else:
		MZM = null
		return
		
	scene = get_tree().get_edited_scene_root()
	
func make_visible(visible: bool):
	pass
	
func handles(object: Object):
	return object is MapZoneManager or object is MapZone
	
func forward_canvas_draw_over_viewport(overlay: Control):
	if not is_instance_valid(MZM):
		return

	for zone in MZM.get_all_visible_zones():
		if is_instance_valid(zone) and zone.visible:
			var handles = get_zone_handles(zone)
			for handle in handles:
				overlay.draw_rect(handle, zone.color, true)
				
			if zone == inspected_zone:
				var pos = handles[CORNERS.TL].position - Vector2.ONE
				var size = handles[CORNERS.BR].position - handles[CORNERS.TL].position +  Vector2.ONE*(handle_size + 2)
				overlay.draw_rect(Rect2(pos, size), Color.white, false)
				
func get_zone_handles(zone: MapZone):
	var size = zone.rect.size
	var pos = zone.rect.position
	
	var transform_viewport = MZM.get_viewport_transform()
	var transform_global = MZM.get_canvas_transform()
	
	var corners = [
		transform_viewport * (transform_global * pos),
		transform_viewport * (transform_global * (pos + Vector2.RIGHT*size)) + Vector2(-handle_size, 0),
		transform_viewport * (transform_global * (pos + Vector2.DOWN*size)) + Vector2(0, -handle_size),
		transform_viewport * (transform_global * (pos + Vector2.ONE*size)) + Vector2(-handle_size, -handle_size)
	]
	
	var handles = []
	for corner in corners:
		handles.append(Rect2(corner, Vector2(handle_size, handle_size)))
		
	return handles
				
func forward_canvas_gui_input(event: InputEvent):
	if not is_instance_valid(MZM) or not MZM.visible:
		return
		
	var zones
	if event is InputEventMouseButton:
		zones = MZM.get_all_visible_zones()
		
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:	
		if not dragged_zone and event.is_pressed():
			for zone in zones:
				if zone is MapZone and zone.visible:
					var handles = get_zone_handles(zone)
					for i in range(len(handles)):
						var handle = handles[i]
						if handle.has_point(event.position):
							var undo = get_undo_redo()
							undo.create_action('Move handle')
							undo.add_undo_method(self, 'update_overlays')
							undo.add_undo_property(zone, 'rect', zone.rect)
							
							dragged_zone = zone
							dragged_handle = handle
							dragged_handle_corner = CORNERS.values()[i]
							return true
			
			for zone in zones:
				if zone is MapZone and zone.visible:
					var handles = get_zone_handles(zone)
					if event.position.x > handles[CORNERS.TL].position.x and event.position.x < handles[CORNERS.TR].position.x + handles[CORNERS.TR].size.x and event.position.y > handles[0].position.y and event.position.y < handles[CORNERS.BL].position.y + handles[CORNERS.BL].size.y:
						var undo = get_undo_redo()
						undo.create_action('Move zone')
						undo.add_undo_method(self, 'update_overlays')
						undo.add_undo_property(zone, 'rect', zone.rect)
							
						dragged_zone = zone
						dragged_zone_offset = event.position - handles[CORNERS.TL].position
						dragged_handle = null
						return true
			
			dragged_zone = map_zone_scene.instance()
			MZM.add_zone(dragged_zone)
			dragged_zone.owner = scene
			dragged_zone.pos = quantize_to_tile_size(to_world_coords(event.position))
			
			var undo = get_undo_redo()
			undo.create_action('Move handle')
			undo.add_undo_method(self, 'update_overlays')
			undo.add_undo_property(dragged_zone, 'rect', dragged_zone.rect)
			
			dragged_handle = get_zone_handles(dragged_zone)[CORNERS.BR]
			dragged_handle_corner = CORNERS.BR
			return true
												
		elif dragged_zone and not event.is_pressed():
			var undo = get_undo_redo()
			undo.add_do_method(self, 'update_overlays')
			undo.add_do_property(dragged_zone, 'rect', dragged_zone.rect)
			undo.commit_action()
			
			if is_instance_valid(dragged_zone):
				get_editor_interface().inspect_object(dragged_zone)
				inspected_zone = dragged_zone
											
			dragged_zone = null
			dragged_handle = null
			return true
		
	if dragged_zone and event is InputEventMouseMotion:
		drag_to(event.position)
		update_overlays()
		return true
		
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT:
		for zone in MZM.get_all_visible_zones():
			if zone is MapZone and zone.visible:
				var handles = get_zone_handles(zone)
				if event.position.x > handles[CORNERS.TL].position.x and event.position.x < handles[CORNERS.TR].position.x + handles[CORNERS.TR].size.x and event.position.y > handles[0].position.y and event.position.y < handles[CORNERS.BL].position.y + handles[CORNERS.BL].size.y:
					if not event.is_pressed():
						MZM.remove_zone(zone)
						zone.free()
						update_overlays()
					return true
		
	return false
		
func drag_to(pos: Vector2):
	pos = to_world_coords(pos)
	
	if is_instance_valid(dragged_zone):
		var tile_size = dragged_zone.TILE_SIZE
		var transform_viewport = MZM.get_viewport_transform()
		var transform_global = MZM.get_canvas_transform()
		
		if dragged_handle:
			var handle_pos = to_world_coords(dragged_handle.position)
			var delta_pos = quantize_to_tile_size(pos - handle_pos)
			var new_rect = dragged_zone.rect
			
			if abs(delta_pos.x) + abs(delta_pos.y) > 0:
				match dragged_handle_corner:
					CORNERS.TL:
						delta_pos.x = min(delta_pos.x, new_rect.size.x - tile_size)
						delta_pos.y = min(delta_pos.y, new_rect.size.y - tile_size)
						
						new_rect.position += delta_pos
						new_rect.size -= delta_pos
							
					CORNERS.TR:
						delta_pos.y = min(delta_pos.y, new_rect.size.y - tile_size)
						
						new_rect.position.y += delta_pos.y
						new_rect.size.y -= delta_pos.y
						new_rect.size.x += delta_pos.x
						
					CORNERS.BL:
						delta_pos.x = min(delta_pos.x, new_rect.size.x - tile_size)
						
						new_rect.position.x += delta_pos.x
						new_rect.size.x -= delta_pos.x
						new_rect.size.y += delta_pos.y
						
					CORNERS.BR:
						new_rect.size += delta_pos
						
				dragged_zone.set_rect(new_rect)
				dragged_handle = get_zone_handles(dragged_zone)[dragged_handle_corner]
			
		else:
			var init_pos = get_zone_handles(dragged_zone)[0].position + dragged_zone_offset
			var delta_pos = pos - to_world_coords(init_pos)
			delta_pos = quantize_to_tile_size(delta_pos)
			
			dragged_zone.pos = dragged_zone.pos + delta_pos
			
func to_screen_coords(vec: Vector2):
	var transform_viewport = MZM.get_viewport_transform()
	var transform_global = MZM.get_canvas_transform()
	return transform_viewport * (transform_global * vec)		

func to_world_coords(vec: Vector2):
	var transform_viewport = MZM.get_viewport_transform()
	var transform_global = MZM.get_canvas_transform()
	return transform_viewport.affine_inverse() * (transform_global.affine_inverse() * vec)
	
func quantize_to_tile_size(vec: Vector2):
		return Vector2(int(vec.x/MapZone.TILE_SIZE)*MapZone.TILE_SIZE, int(vec.y/MapZone.TILE_SIZE)*MapZone.TILE_SIZE)
