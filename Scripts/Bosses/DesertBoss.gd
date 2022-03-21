extends Boss

var ads = [[], [], []]
var total_hp = 0

enum {
	BUDDIES
}

var formation_defs = {
	BUDDIES: {
		'leader': 0,
		'followers': [0, 0] 
	}
}

var formations = []

func add_ad(ad):
	var a = ads[ad.minion_tier]
	var need_new_index = true
	
	for i in range(len(a)):
		if not is_instance_valid(a[i]):
			need_new_index = false
			a[i] = ad
			break
			
	if need_new_index:
		a.append(ad)
		
	total_hp += ad.health
	
func on_ad_damaged(health_lost):
	total_hp -= health_lost
	
func on_ad_death(ad):
	if ad.formation:
		ads[ad.minion_tier].erase(ad)
		
			
			
	
