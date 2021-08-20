class_name Util

const enemy_icon_paths = {
	Enemy.EnemyType.SHOTGUN: 'res://Art/Characters/Shotgunner/icon.png',
	Enemy.EnemyType.CHAIN: 'res://Art/Characters/Ball and Chain Bot/icon.png',
	Enemy.EnemyType.WHEEL: 'res://Art/Characters/Bot Wheel/icon.png',
	Enemy.EnemyType.FLAME: 'res://Art/Characters/flamethrower bot/icon.png',
	Enemy.EnemyType.ARCHER: 'res://Art/Characters/Archer/icon.png',
	Enemy.EnemyType.EXTERMINATOR: 'res://Art/Characters/Exterminator/icon2.png',
	Enemy.EnemyType.SORCERER: 'res://Art/Characters/Sorcerer Bot/icon2.png',
	Enemy.EnemyType.SABER: 'res://Art/Characters/3 Saber dude/icon.png'
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
	
static func choose_weighted(values, weights):
	var cumu_weights = [weights[0]]
	for i in range(1, len(weights)):
		cumu_weights.append(weights[i] + cumu_weights[i-1])
	
	var rand = randf()*cumu_weights[-1]
	for i in range(cumu_weights.size()):
		if rand < cumu_weights[i]:
			return values[i]
		
#https://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Rectangle_difference	
static func rect_difference(r1, r2):
	var result = []
	var top_height = r2.position.y - r1.position.y
	if top_height > 0:
		result.append(Rect2(r1.position.x, r1.position.y, r1.size.x, top_height))
		
	var bottom_y = r2.position.y + r2.size.y
	var bottom_height = r1.size.y - (bottom_y - r1.position.y)
	if bottom_height > 0 and bottom_y < r1.position.y + r1.size.y:
		result.append(Rect2(r1.position.x, bottom_y, r1.size.x, bottom_height))
		
	var y1 = max(r1.position.y, r2.position.y)
	var y2 = min(bottom_y, (r1.position.y + r1.size.y))
	var lr_height = y2 - y1
	
	var left_width = r2.position.x - r1.position.x
	if left_width > 0 and lr_height > 0:
		result.append(Rect2(r1.position.x, y1, left_width, lr_height))
		
	var right_x = r2.position.x + r2.size.x
	var right_width = r1.size.x - (right_x - r1.position.x)
	if right_width > 0 and lr_height > 0:
		result.append(Rect2(right_x, y1, right_width, lr_height))
	
	return result
		
static func rect_from_min_max(max_x, min_x, max_y, min_y):
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
	
static func dist_from_line(point, line_origin, line_dir):
	var a = line_dir.y/line_dir.x
	var c = line_origin.y - a*line_origin.x
	var dist = abs(a*point.x - point.y + c)/sqrt(a*a + 1)
	return dist * sign(sin(line_dir.angle_to(point - line_origin)))
		
