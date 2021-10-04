extends Enemy

const minion = preload("res://Scenes/Characters/Bosses/DesertBossMinion.tscn")

var followers = []

var minion_tier = 2
var ai_target_point = global_position
var ai_move_timer = 0
var minion_spawn_timer = 0


func misc_update(delta):
	ai_move_timer -= delta
	minion_spawn_timer -= delta
	if minion_spawn_timer < 0:
		spawn_minions()
		minion_spawn_timer = 1 + randf()*0.1

func ai_move():
	if ai_move_timer < 0:
		var to_player = GameManager.player.global_position - shape.global_position
		var player_dist = to_player.length()
		ai_move_timer = 0.7 + randf()
		if player_dist > 300:
			target_velocity = Vector2.ZERO
			
		elif to_player.length() < 100:
			target_velocity = -to_player 
		else:
			if randf() < 0.5:
				ai_target_point = shape.global_position + Vector2(randf()-0.5, randf()-0.5)*150
			
			var to_target_point = ai_target_point - shape.global_position
			
			if to_target_point.length() > 5:
				target_velocity = to_target_point
			else:
				ai_target_point = shape.global_position
				target_velocity = Vector2.ZERO

func spawn_minions():
	var new_child = minion.instance().duplicate()
	self.get_parent().add_child(new_child)
	new_child.global_position = self.global_position
	new_child.attacking = true
	new_child.leader = self
	followers.append(new_child)
	new_child.animplayer.play("Spawn")
	
func on_follower_death(follower):
	followers.erase(follower)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Die":
		if is_in_group("enemy"):
			actually_die()
