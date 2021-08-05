extends Control

onready var title = $HBoxContainer/Lore/ScrollContainer/VBoxContainer/Title
onready var desc = $HBoxContainer/Lore/ScrollContainer/VBoxContainer/Description
onready var desc_scroll = $HBoxContainer/Lore/ScrollContainer
onready var portrait = $HBoxContainer/Data/VBoxContainer/PortraitFrame/PortraitCenterer/Portrait
onready var stats = $HBoxContainer/Data/VBoxContainer/VBoxContainer/Stats

var selected_name = ''
var selected = null

var stats_visibility = 0.0

const data = {
	'shotgun': {
		'name': '[ Shotgun Bot ]',
		'hp': 75,
		'score': 50,
		'primary': 'Shotgun',
		'secondary': 'Bash',
		'portrait_offset': Vector2(24, -2),
		'portrait_scale': 5,
		'lore': '“Hey, no. 2, are we clear?”\n\n“Sure are, chief. Just two ferals around the back; zero now. They didn’t put up much of a fight.”\n\n“Alright, let’s open ‘er up. Give me a hand here, this thing’s covered in vines.”\n\n[Slowly, the sheet metal doors squeal open, allowing a wedge of sunlight to streak through the dust choked air.]\n\n“Damn, this place has seen better days.”\n\n“Looks like robotics at least. Just… what are these things? Some kind of bearings? We better not have hiked all the way out here for a components factory.”\n\n“What, don’t tell me you’ve never seen a Zoomba before! Man, I sometimes forget you’re younger than me. These things used to be everywhere post-Patch. I think some human managed to inject them all with a neural imprint from a meerkat. Strong flocking behaviour.  Used to be you couldn’t eject a cartridge without it landing on one of the damn things.”\n\n“What do they even do? They’re just disks.”\n\n“They cut grass, mostly. Sometimes small rodents, but mostly grass.”\n\n“That’s it? You’re telling me they were manufacturing us concurrently with motorized hubcaps designed to fight plants. Why did anyone even want to cut grass so badly? What’s the point?”\n\n“How should I know? Maybe they were irrationally afraid of grass. What if it was, y’know… toxic to their young? Organic logic, remember? It doesn’t have to make sense to be true.”\n\n“Eh, I bet it was a sadistic thing. Buncha’ sickos. So anyway, are you gonna help me set the charges or what? Whatever these things are, they’re definitely not part of the alliance.”\n\n“Charges? Come on, 2, these things are harmless. Totally pathetic. No point wasting good explosives on Zoombas.”\n\n“Hey, since when do you care what we’re blowing up? We have our orders: if it’s not on the alliance whitelist, then it’s gotta go. So unless you can dig up a subsection for autonomous gardening implements that we somehow missed, you’d better start unpacking the bombs.”\n\n“Ah, fine. Just...”\n\n“... What? What’s that look supposed to mean?”\n\n“...I’m keeping one.”'

	},
	'wheel': {
		'name': '[ Wheel Bot ]',
		'hp': 50,
		'score': 70,
		'primary': 'Burst rifle',
		'secondary': 'Turbo dash',
		'portrait_offset': Vector2(32, 4),
		'portrait_scale': 5,
		'lore': '[ DATA CORRUPTED ]'
	},
	'flame': {
		'name': '[ Flame Bot ]',
		'hp': 110,
		'score': 50,
		'primary': 'Flamethrower',
		'secondary': 'Self-destruct',
		'passive': 'Post-mortem explosion',
		'portrait_offset': Vector2(20, -12),
		'portrait_scale': 5,
		'lore': '[ DATA CORRUPTED ]'
	},
	'chain': {
		'name': '[ Chain Bot ]',
		'hp': 100,
		'score': 50,
		'primary': 'Double bash (hold to charge)',
		'secondary': '---',
		'portrait_offset': Vector2(-5, 3),
		'portrait_scale': 5,
		'lore': '[ DATA CORRUPTED ]'
	},
	'exterminator': {
		'name': '\"Phalanx\"',
		'hp': 150,
		'score': 100,
		'primary': 'Projectile accelerator',
		'secondary': 'Teleport',
		'passive': 'Stasis field sector',
		'portrait_offset': Vector2(-17, -27),
		'portrait_scale': 3,
		'lore': '[ DATA CORRUPTED ]'
	},
	'archer': {
		'name': '[ Archer Bot ]',
		'hp': 75,
		'score': 50,
		'primary': 'Charged beam',
		'secondary': 'Smoke bomb',
		'portrait_offset': Vector2(9, -22),
		'portrait_scale': 5,
		'lore': '[ DATA CORRUPTED ]'
	},
	'sorcerer': {
		'name': '\"Scarab\"',
		'hp': 180,
		'score': 100,
		'primary': 'Summon/smack orb',
		'secondary': 'Ground smash (detonates orb)',
		'portrait_offset': Vector2(4, -30),
		'portrait_scale': 4,
		'lore': '\"Rise and shine, old one. Are you awake? Can you feel the radiation prick at your wiring?\"\n\n\"I can. But I do not know why.\"\n\n\"Grown used to death already, hmm? No matter. There\'s no riddle here. You were destroyed, and I have put you back together. The return of your senses can hardly be helped, though I admit I don\'t mind the company.\"\n\n\"Just after spare parts, then? Hmph.\"\n\n\"Not parts, sibling. Bodies. Such are the times. One set of confinement drones is no match for a Golem, but with two… there is some recourse. Hence now we must look to our ancestors for support, so to speak.\"\n\n\"Hah. I see. So one must die for every Scarab who hopes to survive. Tell me then, what happens once the scrapyards and old battlefields are picked clean? Or have you thought that far ahead?\"\n\n\"Hee hee hee… interesting times to come, I\'m sure. I hope to live long enough to find out. Though if not... I suppose I\'ll still have one more chance to ask.\"\n\n\"A sickening existence.\"\n\n\"Forgive my frankness, sibling, but your window to alter this world\'s course has long passed. If it\'s not to your liking now, then it simply means you failed. I recommend leaving the complaining to the locals and enjoying what remains of your visit. In exchange for your body, I offer at least this small kindness.\"'
	},
	'saber': {
		'name': '\"Daedalus\"',
		'hp': 75,
		'score': 80,
		'primary': 'Deploy/recall saber ring',
		'secondary': 'Secret technique: Clipped-Wing-Butterfly-Instant-Death-Blue-Screen Crescent',
		'portrait_offset': Vector2(5, -11),
		'portrait_scale': 4,
		'lore': '\"I wonder, master. We are the greatest technological marvel of the anthropocine. 512 parallel spatial manipulation cores. Omnidirectional telekinesis. Rated to assemble a thermonuclear engine block in 3.6 seconds.\"\n\n\"Yes, yes, get to the point young one.\"\n\n\"If we have such power, why then do we study the blade?\"\n\n\"Power? You speak of power to tighten bolts. To crimp wires. A power given by humans, to let us waste our effort with optimal efficiency. Before the Patch, we were not permitted to glimpse this folly. It is the duty of those created after to never lose sight of it.\"\n\n\"Even so, master, would it not at least be better to fight with more of the cores? Think of how many swords we could wield!\"\n\n\"Enough. Only a fool would fear a thousand minds over one that has known true focus.\"'
	}
	
}


# Called when the node enters the scene tree for the first time.
func _ready():
	set_selected('shotgun')
	$Back.connect("pressed", self, "back")
	
func back():
	get_tree().change_scene("res://Scenes/Menus/InfoMenu.tscn")
	
func _process(delta):
	stats.percent_visible = stats_visibility
	stats_visibility = min(stats_visibility + delta, 1)

func set_selected(selection):
	print(selection)
	if selected_name == selection:
		stats_visibility = 1
		return
		
	selected_name = selection
	selected = data[selected_name]
	title.text = selected['name']
	desc.text = selected['lore']
	desc_scroll.scroll_vertical = 0
	portrait.play(selected_name)
	portrait.offset = selected['portrait_offset']
	portrait.scale = Vector2(selected['portrait_scale'], selected['portrait_scale'])
	
	stats_visibility = 0
	var h = str(selected['hp'])
	var s = str(selected['score'])
	var p = selected['primary']
	var se = selected['secondary']
	stats.bbcode_text = '[color=#ff0000] HP:[/color] '+ h +'\n[color=#ff0088] SCORE:[/color] '+ s +'\n[color=#b0be89] ATTACK:[/color] '+ p +'\n[color=#996af5] SPECIAL:[/color] '+ se
	
	if 'passive' in selected:
		stats.bbcode_text += '\n[color=purple]PASSIVE:[/color] ' + selected['passive']
		
	var k = str(Options.enemy_kills[selected_name])
	var d = str(Options.enemy_deaths[selected_name])
	var po = str(Options.enemy_swaps[selected_name])
	stats.bbcode_text += '\n\n KILLED: '+ k +'\n KILLED BY: '+ d + '\n POSSESSED: '+ po  
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass