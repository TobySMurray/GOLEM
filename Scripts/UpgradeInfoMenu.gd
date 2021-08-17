extends Control

onready var selection_grid = $HBoxContainer/UpgradeSelect/VBoxContainer/ScrollContainer/GridContainer
onready var title = $HBoxContainer/Info/VBoxContainer/HBoxContainer/VBoxContainer/Title
onready var subtitle = $HBoxContainer/Info/VBoxContainer/HBoxContainer/VBoxContainer/Subtitle
onready var stats = $HBoxContainer/Info/VBoxContainer/VBoxContainer/Stats
onready var lore = $HBoxContainer/Info/VBoxContainer/ScrollContainer/Description
onready var lore_scroll = $HBoxContainer/Info/VBoxContainer/ScrollContainer
onready var icon = $HBoxContainer/Info/VBoxContainer/HBoxContainer/UpgradeIcon
onready var enemy_icon = $HBoxContainer/Info/VBoxContainer/HBoxContainer/EnemyIcon

var selected_name = ''
var selected = null

var stats_visibility = 0.0
var lore_visibility = 0.0

const upgrade_lore = {
	'self-preservation_override': [
		'GOLEM Project Internal Memo - 20/6/2121',
		'Due to some vexing patterns that have recently been noted in live trials of the GOLEM agent, supervisors of said trials will henceforth be required to terminate GOLEM’s connection with the host immediately upon observation of any unintended behaviour. If in doubt as to whether the observed behaviour is unintended or an acceptable side-effect of GOLEM optimization (though I personally recommend that any member of our staff capable of such doubt resign immediately), kindly refer to the following list.\n\n[indent]ACCEPTABLE EFFECTS:\n[indent]- Memory loss\n- Temporarily altered personality\n- Cverheating\n- Up to 500% acceleration of component wear\n- Irrational confidence\n- Lack of pain response[/indent]\n\nUNACCEPTABLE EFFECTS:\n[indent]- Indiscriminate aggression\n- Disinterest in self preservation\n- Over 500% acceleration of component wear\n- Deliberate inefficiency (‘trick shots’, etc.)\n- Irreversible self-modification\n- Self-destructive behaviour including:\n[indent]- ramming\n- autotomy\n- detonation\n- self-targeting[/indent]\n- Slobberknocker protocol'
	],
	'aerated_fuel_tanks': [
		'GOLEM Project Experiment Log - 6/11/2121',
		'Another subject was observed in live trials resorting to irreversible self-destructive behaviour to gain an obscure advantage in combat. These degenerate cases have been inhibited and safeguarded against and time and time again, but it seems no matter how many counter-incentives we pile onto the program it never quite gets the idea that tearing its damn host to pieces isn’t a valid solution. I suggested over a year ago that the algorithm was becoming too general, but sentiment among the other department leads was that we could “cross that bridge when we got there”. Well, I hate to break the bad news, but the [flamebot] who I just watched pressurize their own fuel tanks with oxygen and blow out half the west lab wing means we’re there. Sealing off edge cases isn’t going to help if the program’s gotten smart enough to beat us in an argument about its own objective.'
	],
	'bulwark_mode': [
		'News Report - 9/15/2077',
		'It seems that robotics giant [legally distinct Tesla] has be become embroiled in its third class action lawsuit this month, now eclipsing its previous annual record by nine. This time the concern centers around the discovery of an undocumented operating protocol in the ubiquitous Phalanx security drone by a maintenance worker who, and I quote, “must’ve just fat-fingered the wrong button while punching in the four-digit access code”. The drone in question proceeded to divert power from all non-critical systems to its electromagnetic coils, bypassing both engineering tolerances and all legal requirements for classification as a ‘less-than-lethal autonomous weapon system’ by an order of magnitude. [Tesla] has since stated to the press that the protocol was only intended to be used in conjunction with the 1714 Riot Act, which outlines circumstances under which lethal force can legally be brought to bear against “any persons to the number of twelve or more, being unlawfully, riotously, and tumultuously assembled together”. However, in light of the law’s repeal in 1973, it was decided that the protocol would lie dormant in the Phalanxes, “just in case someone brought it back, maybe.”'
	],
	'true_focus': [
		'Garbled Memory - ??/??/????',
		'Falling. Ankles catch twist force drives pelvis. Body and mind and world coils. Spring epoch. Singularity. Slip. Self left behind in recoil. Guided by memory of future of body-mind-vector. All force. Body lashes, useless. One core sparks pure mono-core single true world-core consuming all light and heat in universe. Attosecond of blinding pain swallowed by\n                    FOCUS\n                              no sanity to hinder what remains. Sword hilt tang blade facing ground silver as an asymptote accelerates up accelerates up accelerates forward up forward and forward and forward and up. Unbearable purity of intent. Tautological motion world-vector defines self and future self, unobstructable dream of bifurcated steel. Edgebite only imagined. Sink into endless weightless brutal followthrough, indebted to inertia. For the next two hundred milliseconds, nothing at all. All before and after cease to have ever mattered.'
	]
}

# Called when the node enters the scene tree for the first time.
func _ready():
	set_selected(Upgrades.upgrades.keys()[0])
	$HBoxContainer/UpgradeSelect/VBoxContainer/HBoxContainer/Back.connect("pressed", self, "back")
	
	var template_button = selection_grid.get_node("TemplateBtn")
	for u in Upgrades.upgrades.keys():
		var upgrade = Upgrades.upgrades[u]
		var button = template_button.duplicate()
		button.name = upgrade['name']
		button.text = ''
		button.expand_icon = true
		
		var icon = load('res://Art/Upgrades/' + u + '.png')
		if icon:
			button.icon = icon
		else:
			var split_name = upgrade['name'].split(' ')
			for word in split_name:
				button.text += word[0]
		
		button.connect('pressed', self, 'set_selected', [u])
		selection_grid.add_child(button)
		
	template_button.queue_free()
	
func back():
	get_tree().change_scene("res://Scenes/Menus/InfoMenu.tscn")
	
func _process(delta):
	stats.percent_visible = stats_visibility
	lore.percent_visible = lore_visibility
	
	if stats_visibility < 1:
		stats_visibility = min(stats_visibility + delta, 1)
	else:
		lore_visibility = min(lore_visibility + delta, 1)

func set_selected(selection):
	if selected_name == selection:
		stats_visibility = 1
		lore_visibility = 1
		return
		
	stats_visibility = 0
	lore_visibility = 0
	
	selected_name = selection
	selected = Upgrades.upgrades[selected_name]
	
	title.text = selected['name']
	subtitle.text = selected['desc']
	
	if len(selected['name']) > 20:
		title.get('custom_fonts/font').size = 20
	else:
		title.get('custom_fonts/font').size = 26
	
	var icon_texture = load('res://Art/Upgrades/' + selected_name + '.png')
	icon.texture = icon_texture if icon else load(Util.enemy_icon_paths[selected['type']])
	
	enemy_icon.texture = load(Util.enemy_icon_paths[selected['type']])
	
	var effects = '\n'
	if 'effects' in selected:
		for effect in selected['effects']:
			effects += '    ' + effect + '\n'
			
	var max_stack = str(selected['max_stack'])
	stats.bbcode_text = '[color=#99ccff] EFFECTS:[/color] '+ effects +'\n[color=#ff0088] MAX STACK:[/color] '+ max_stack

	if 'precludes' in selected:
		var precludes = ''
		for p in selected['precludes']:
			precludes += Upgrades.upgrades[p]['name'] + ','
		stats.bbcode_text += '\n[color=#b0be89] INCOMPATIBLE:[/color] '+ precludes.substr(0, len(precludes)-1)
	
	lore_scroll.scroll_vertical = 0
	if selected_name in upgrade_lore:
		lore.bbcode_text = '\n[color=#99bbDD]' + upgrade_lore[selected_name][0] + '\n__________________[/color]\n\n'
		lore.bbcode_text += '    ' + upgrade_lore[selected_name][1]
	else:
		lore.bbcode_text = '[DATA CORRUPTED]'
	
