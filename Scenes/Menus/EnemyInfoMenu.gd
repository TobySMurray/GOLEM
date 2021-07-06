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
		'name': 'Shotgun Bot',
		'hp': 75,
		'score': 50,
		'primary': 'Shotgun',
		'secondary': '---',
		'portrait_offset': Vector2(24, -2),
		'portrait_scale': 5,
		'lore': 'There once was a man from Nantucket'
	},
	'wheel': {
		'name': 'Wheel Bot',
		'hp': 50,
		'score': 70,
		'primary': 'Burst rifle',
		'secondary': 'Turbo dash',
		'portrait_offset': Vector2(32, 4),
		'portrait_scale': 5,
		'lore': 'There once was a man from Nantucket'
	},
	'flame': {
		'name': 'foobar',
		'hp': 110,
		'score': 50,
		'primary': 'Flamethrower',
		'secondary': 'Self-destruct',
		'passive': 'Post-mortem explosion',
		'portrait_offset': Vector2(20, -12),
		'portrait_scale': 5,
		'lore': 'There once was a man from Nantucket'
	},
	'chain': {
		'name': 'foobar',
		'hp': 100,
		'score': 50,
		'primary': 'Double bash (hold to charge)',
		'secondary': '---',
		'portrait_offset': Vector2(-5, 3),
		'portrait_scale': 5,
		'lore': 'There once was a man from Nantucket'
	},
	'exterminator': {
		'name': 'foobar',
		'hp': 150,
		'score': 100,
		'primary': 'Kinetic pulse',
		'secondary': 'Teleport',
		'passive': 'Stasis field sector',
		'portrait_offset': Vector2(-17, -27),
		'portrait_scale': 3,
		'lore': 'There once was a man from Nantucket'
	},
	'archer': {
		'name': 'foobar',
		'hp': 75,
		'score': 50,
		'primary': 'Charged beam',
		'secondary': 'Smoke bomb',
		'portrait_offset': Vector2(9, -22),
		'portrait_scale': 5,
		'lore': 'There once was a man from Nantucket'
	},
	'sorcerer': {
		'name': 'foobar',
		'hp': 180,
		'score': 100,
		'primary': 'Summon/smack orb',
		'secondary': 'Ground smash (detonates orb)',
		'portrait_offset': Vector2(4, -30),
		'portrait_scale': 4,
		'lore': 'There once was a man from Nantucket'
	},
	'saber': {
		'name': 'Daedalus-888',
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
	
func _process(delta):
	stats.percent_visible = stats_visibility
	stats_visibility = min(stats_visibility + delta, 1)

func set_selected(selection):
	print(selection)
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