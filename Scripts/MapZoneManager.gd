tool
extends Node2D

class_name MapZoneManager
export var zones = []
export (bool) var reread_zones = false setget reread_zones

func add_zone(zone: MapZone):
	zones.append(zone)
	#ensure_container_existence(zone.zone_type)
	add_child(zone)
	
func remove_zone(zone: MapZone):
	zones.erase(zone)
	remove_child(zone)
	
func reread_zones(var value):
	for zone in get_children():
		if not zone in zones:
			zones.append(zone as MapZone)
			zone.set_props(zone.properties)
		
#func retype_zone(zone, new_type):
#	zones[zone.zone_type].erase(zone)
#	zones[new_type].append(zone)
#
#	ensure_container_existence(new_type)
#	zone.get_parent().call_deferred('remove_child', zone)
#	call_deferred('add_child', zone)
#	zone.set_deferred('owner', get_tree().get_edited_scene_root())
	

func get_all_visible_zones():
	#var zone_list = []
	if visible:
		return zones
#		for zone_type in zones.keys():
#			if zone_containers[zone_type] and zone_containers[zone_type].visible:
#				zone_list += zones[zone_type]	
	return []
	
#func ensure_container_existence(zone_type):
#	if not is_instance_valid(zone_containers[zone_type]):
#		var container = get_node_or_null(MapZone.ZoneType.keys()[zone_type])
#		if container and not container.is_inside_tree():
#			container.free()
#			container = null
#		if not container:
#			container = Node2D.new()
#			add_child(container)
#			container.owner = get_tree().get_edited_scene_root()
#			container.name = MapZone.ZoneType.keys()[zone_type]
#		zone_containers[zone_type] = container
