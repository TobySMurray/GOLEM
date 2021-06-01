class_name Util

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
		
