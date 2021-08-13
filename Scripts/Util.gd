class_name Util

const enemy_icon_paths = {
	'shotgun': 'res://Art/Characters/Shotgunner/icon.png',
	'chain': 'res://Art/Characters/Ball and Chain Bot/icon.png',
	'wheel': 'res://Art/Characters/Bot Wheel/icon.png',
	'flame': 'res://Art/Characters/flamethrower bot/icon.png',
	'archer': 'res://Art/Characters/Archer/icon.png',
	'exterminator': 'res://Art/Characters/Exterminator/icon2.png',
	'sorcerer': 'res://Art/Characters/Sorcerer Bot/icon2.png',
	'saber': 'res://Art/Characters/3 Saber dude/icon.png'
}

static func signed_wrap(a):
	if a > PI:
		return a - 2*PI
	elif a < -PI:
		return a + 2*PI
	return a
	
static func unsigned_wrap(a):
	if a > 2*PI:
		return a - 2*PI
	elif a < 0:
		return a + 2*PI
	return a

static func signed_wrap_deg(a):
	if a > 180:
		return a - 360
	elif a < -180:
		return a + 360
	return a
	
static func unsigned_wrap_deg(a):
	if a > 360:
		return a - 360
	elif a < 0:
		return a + 360
	return a
	
static func limit_horizontal_angle(dir, limit_angle):
	var angle = dir.angle()
	if abs(angle) > limit_angle and abs(angle) < PI - limit_angle:
		if abs(angle) < PI/2:
			angle = limit_angle*sign(angle)
		else:
			angle = (PI - limit_angle)*sign(angle)
			
	return Vector2(cos(angle), sin(angle))
	
static func remove_invalid(a):
	var length = len(a)
	var shift_size = 0
	for i in range(length):
		while i + shift_size < length and not is_instance_valid(a[i + shift_size]):
			shift_size += 1
			
		if i + shift_size >= length:
			break
			
		if shift_size > 0:
			a[i] = a[i + shift_size]
	
	length -= shift_size
	a.resize(length)
	
static func reparent_to(child, new_parent):
	var pos = child.global_position
	child.get_parent().remove_child(child)
	new_parent.add_child(child)
	child.set_owner(new_parent)
	child.global_position = pos
	
		
