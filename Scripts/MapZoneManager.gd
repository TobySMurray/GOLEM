tool
extends Node2D

class_name MapZoneManager

export var zones = {
	MapZone.ZoneType.SPAWN: [],
	MapZone.ZoneType.NO_TP: []
}

var zone_containers = {
	MapZone.ZoneType.SPAWN: null,
	MapZone.ZoneType.NO_TP: null
}

func add_zone(zone: MapZone):
	zones[zone.zone_type].append(zone)
	ensure_container_existence(zone.zone_type)
	zone_containers[zone.zone_type].add_child(zone)
	
func remove_zone(zone: MapZone):
	zones[zone.zone_type].erase(zone)
	if is_instance_valid(zone_containers[zone.zone_type]):
		zone_containers[zone.zone_type].remove_child(zone)
		
func retype_zone(zone, new_type):
	zones[zone.zone_type].erase(zone)
	zones[new_type].append(zone)
	
	ensure_container_existence(new_type)
	zone.get_parent().call_deferred('remove_child', zone)
	zone_containers[new_type].call_deferred('add_child', zone)
	zone.set_deferred('owner', get_tree().get_edited_scene_root())
	

func get_all_visible_zones():
	var zone_list = []
	if visible:
		for zone_type in zones.keys():
			if zone_containers[zone_type] and zone_containers[zone_type].visible:
				zone_list += zones[zone_type]
			
	return zone_list
	
func ensure_container_existence(zone_type):
	if not is_instance_valid(zone_containers[zone_type]):
		var container = get_node_or_null(MapZone.ZoneType.keys()[zone_type])
		if container and not container.is_inside_tree():
			container.free()
			container = null
		if not container:
			container = Node2D.new()
			add_child(container)
			container.owner = get_tree().get_edited_scene_root()
			container.name = MapZone.ZoneType.keys()[zone_type]
		zone_containers[zone_type] = container
