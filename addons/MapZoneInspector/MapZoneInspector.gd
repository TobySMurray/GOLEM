tool
extends EditorInspectorPlugin


func can_handle(object: Object):
	return object is MapZoneManager
	
func parse_property(object, type, path, hint, hint_text, usage):
	return
