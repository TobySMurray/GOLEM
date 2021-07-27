class_name Upgrades

const upgrades = {
	#SHOTGUN
	'induction_barrel': { #Replaces pellets with piercing flame bullets
		'name': 'Induction Barrel',
		'desc': 'Molten buckshot.',
		'effects': ['Shotgun pellets are replaced with piercing flames'],
		'type': 'shotgun',
		'max_stack': 1
	},
	'stacked_shells': { #Increase spread, reload time, and number of projectiles
		'name': 'Stacked Shells',
		'desc': 'The thinking bot\'s sawed-off.',
		'effects': ['+100% pellet quantity', '+100% pellet spread', '+50% reload time'],
		'type': 'shotgun',
		'max_stack': 3
	},
	'shock_stock': { #Melee attack stuns
		'name': 'Shock Stock',
		'desc': 'Keep your hands on the rubber grips.',
		'effects': ['Melee attack stuns for 1.5 seconds (+1.5 per stack)'],
		'type': 'shotgun',
		'max_stack': 2
	},
	'soldering_fingers': { #Pellets are replaced by large projectile that bursts into pellets on inpact
		'name': 'Soldering Fingers',
		'desc': '50% shot, 50% slug, 100% fragmentation hazard.',
		'effects': ['Shotgun pellets are replaced with a slug that deals 30 damage and fragments on impact'],
		'type': 'shotgun',
		'max_stack': 1
	},
	'reload_coroutine': { #Decreases reload time and makes shotgun full-auto
		'name': 'Reload Coroutine',
		'desc': 'You didn\'t reload, but your CPU did.',
		'effects': ['-20% reload time', 'Shotgun becomes full-auto'],
		'type': 'shotgun',
		'max_stack': 3
	},
	
	#CHAIN
	'precompressed_hydraulics': { #Increase initial charge level
		'name': 'Precompressed Hydraulics',
		'desc': 'Fear the jab.',
		'effects': ['Attacks start as though charged for 0.3 seconds (+0.3 per stack)', '-20% attack charge speed'],
		'type': 'chain',
		'max_stack': 2
	},
	'adaptive_wrists': { #Decrease knockback, increase damage
		'name': 'Adaptive Wrists',
		'desc': 'Swing for the kill, not the fences.',
		'effects': ['+20% melee damage', '-50% melee knockback'],
		'type': 'chain',
		'max_stack': 1
	},
	'discharge_flail': { #Attack stuns when charged
		'name': 'Discharge Flail',
		'desc': 'Incapacitating capacitors. Requires charge.',
		'effects': [],
		'type': 'chain',
		'max_stack': 2
	},
	'vortex_technique': { #Replaces shockwaves with one big piercing shockwave
		'name': 'Vortex Technique',
		'desc': '\"Laminar whipcracks are not possible.\"\n    - An Idiot',
		'effects': ['Shockwaves are replaced by a single piercing vortex wave that sucks in enemies', 'Vortex wave size, damage, and knockback scale with charge level'],
		'type': 'chain',
		'max_stack': 1
	},
	'footwork_scheduler': { #Increase movement speed while charging
		'name': 'Footwork Scheduler',
		'desc': 'Get as close as you\'d like.',
		'effects': ['Maintain 40% of base speed while charging (+40% per stack)', 'Lunge forward during each swing', 'Can change attack direction while charging'],
		'type': 'chain',
		'max_stack': 2
	},
	
	#WHEEL
	'advanced_targeting': { #Replace manual aiming with auto targeting
		'name': 'Advanced Targeting',
		'desc': 'Aiming is for pedestrians.',
		'effects': ['Pulse rifle locks on to the enemy nearest the reticle and aims automatically'],
		'type': 'wheel',
		'max_stack': 1
	},
	'bypassed_muffler': { #Dashing shoots a clound of flame bullets backward
		'name': 'Bypassed Muffler',
		'desc': 'Lethal exhaust.',
		'effects': ['Emit a cloud of flames backward when dashing'],
		'type': 'wheel',
		'max_stack': 1
	},
	'self-preservation_override': { #Hitting enemies deals velocity-based damage
		'name': 'Self-Preservation Override',
		'desc': 'Become the bullet.',
		'effects': ['Deal contact damage to enemies based on your speed', 'Take 3 damage per collision'],
		'type': 'wheel',
		'max_stack': 1
	},
	'manual_plasma_throttle': { #Pulses can be charged (Chocolate Milk from Isaac)
		'name': 'Manual Plasma Throttle',
		'desc': 'Your pulses, your way.',
		'effects': ['Pulse burst is replaced by a single pulse that can be charged for up to 2 seconds.'],
		'type': 'wheel',
		'max_stack': 1
	},
	'top_gear': { #Increase max speed, decrease acceleration, preserve speed after dash
		'name': 'Top Gear',
		'desc': 'GAS GAS GAS.',
		'effects': ['+50% top speed', '-40% accleration'],
		'type': 'wheel',
		'max_stack': 1
	},
	
	#FLAME
	'pressurized_hose': { # Increase pressure dropoff and max pressure, decrease start-lag
		'name': 'Pressurized Hose',
		'desc': 'Premature conflagration.',
		'effects': ['-50% ignition time', '+20% fire volume', '+40% pressure dropoff'],
		'type': 'flame',
		'max_stack': 2
	},
	'optimized_regulator': { #Decrease pressure drop-off and max pressure, decrease movement penalty
		'name': 'Optimized Regulator',
		'desc': 'Slow burn, easier to handle.',
		'effects': ['-50% pressure dropoff', '+75% speed while firing', '-15% fire volume'],
		'type': 'flame',
		'max_stack': 2
	},
	'internal_combustion': { #Increase range and decrease spread, add constant backward recoil
		'name': 'Internal Combustion',
		'desc': 'Handheld rocket engine.',
		'effects': ['+50% flame range', 'Greatly reduced flame spread', 'Accelerate backwards while firing'],
		'type': 'flame',
		'max_stack': 1,
		'precludes': ['ultrasonic_nozzle']
	},
	'ultrasonic_nozzle': { #Replace flames with gas clouds which all explode after a delay
		'name': 'Ultrasonic Nozzle',
		'desc': 'WARNING: Thermobaric blast rated visor mandatory.',
		'effects': ['Flames are replaced with gas clouds that explode after you stop firing'],
		'type': 'flame',
		'max_stack': 1,
		'precludes': ['internal_combustion']
	},
	'aerated_fuel_tanks': { #Increase size of post-mortem explosion
		'name': 'Aerated Fuel Tanks',
		'desc': 'What could go wrong?',
		'effects': ['Greatly increase size and power of post-mortem explosion'],
		'type': 'flame',
		'max_stack': 1
	},
	
	#ARCHER
	'vibro-shimmy': { # Allow movement while charging
		'name': 'Vibro-Shimmy',
		'desc': 'Deadly on the battlefield, killer on the dancefloor.',
		'effects': ['Maintain 50% base walk speed while charging (+50% per stck)'],
		'type': 'archer',
		'max_stack': 2
	},
	'half-draw': { # Halves charge time, reduces damage and knockback, removes explosions
		'name': 'Half-Draw',
		'desc': '\"Full auto.\"',
		'effects': ['-50% charge time (x0.5 per stack)', 'Can aim while charging', 'Bow is full-auto', '-66% beam damage (-30% per stack)'],
		'type': 'archer',
		'max_stack': 3
	},
	'slobberknocker_protocol': { # Increases beam width and damage
		'name': 'Slobberknocker Protocol',
		'desc': 'Slobberknocker protocol.',
		'effects': ['+200% beam width', '+50% beam damage'],
		'type': 'archer',
		'max_stack': 2
	},
	'scruple_inhibitor': { # Contact damage while in stealth
		'name': 'Scruple Inhibitor',
		'desc': 'Shank \'em good! Right in the oil filter!',
		'effects': ['Deal 50 contact damage while in stealth mode (+10 per Evolution Level)', 'Kills in stealth give +50% score'],
		'type': 'archer',
		'max_stack': 1
	},
	
	#EXTERMINATOR
	'improvised_projectiles': { # Periodically generate new captured bullets
		'name': 'Improvised Projectiles',
		'desc': 'I think they\'re called \"rocks\".',
		'effects': ['Generate 1.5 captured bullets per second (+1.5 per stack)'],
		'type': 'exterminator',
		'max_stack': 2
	},
	'high-energy_orbit': { # Increase minimum rotation speed of captured bullets
		'name': 'High-Energy Orbit',
		'desc': 'Shoot first, aim later.',
		'effects': ['+100% resting bullet charge'],
		'type': 'exterminator',
		'max_stack': 1
	},
	'synchotron_accelerator': { # Bullets turn into lasers one by one while attacking
		'name': 'Synchotron Accelerator',
		'desc': 'Maybe you\'ll find the Higgs...',
		'effects': [],
		'type': 'exterminator',
		'max_stack': 1,
	},
	'exposed_coils': { # Increase shield breadth
		'name': 'Exposed Coils',
		'desc': 'Extra protection, except against the mecha-cancer.',
		'effects': ['+90% shield width'],
		'type': 'exterminator',
		'max_stack': 2
	},
	'bulwark_mode': { # Bullets accelerate faster and explode. Must stop moving to fire. 
		'name': 'Bulwark Mode',
		'desc': 'No retreat. No mercy.',
		'effects': ['+100% bullet charge speed', 'Bullets/lasers explode for +50% damage', 'Cannot move while attacking'],
		'type': 'exterminator',
		'max_stack': 1,
	},
	'particulate_screen': { # Shield can deflect lasers
		'name': 'Particulate Screen',
		'desc': 'SPF 1,000,000.',
		'effects': ['Stasis field can deflect lasers'],
		'type': 'exterminator',
		'max_stack': 1,
	},
	
	#SORCERER
	'elastic_containment': { #Increase orb size, decrease knockback (does not affect terrain collision)
		'name': 'Elastic Containment',
		'desc': 'Less Sol, more Betelgeuse.',
		'effects': ['+100% orb size'],
		'type': 'sorcerer',
		'max_stack': 2
	},
	'parallelized_drones': { #Decrease orb size, add additional orb
		'name': 'Parallelized Drones',
		'desc': 'Divide and conquer.',
		'effects': ['+1 orb', '-25% orb size', '-20% orb damage (-(20/n)% per n-th stack)'],
		'type': 'sorcerer',
		'max_stack': 4
	},
	'docked_drones': { #Increase orb speed and deceleration, limits orb to short radius around controller 
		'name': 'Docked Drones',
		'desc': 'Tokamak teatherball.',
		'effects': ['+100% orb smack speed', '-40% orb damage', 'Orb is bound to a small radius around host'],
		'type': 'sorcerer',
		'precludes': ['precision_handling'],
		'max_stack': 1
	},
	'precision_handling': { #Orb accelerates toward mouse instead of being smacked, and stops when LMB released
		'name': 'Precision Handling',
		'desc': '\"Quick, the safety inspector\'s coming...\"',
		'effects': ['Orb is pushed continuously toward reticle instead of smacked'],
		'type': 'sorcerer',
		'precludes': ['docked_drones'],
		'max_stack': 1
	},
	
	#SABER
	'fractured_mind': { #Decrease saber ring knockback, replaces saber ring with a spinning ring of three saber rings
		'name': 'Fractured Mind',
		'desc': 'That\'s a lot of swords.',
		'effects': ['Saber ring becomes a ring of 3 saber rings'],
		'type': 'saber',
		'max_stack': 1
	},
	'true_focus': { # Triples CWBIDBSC damage, increases dash speed and time dilation, cannot die during dash
		'name': 'True Focus',
		'desc': 'Ten milliseconds, a trillion clock cycles,\none strike.',
		'effects': ['+200% C.W.B.I.D.B.S.C. damage', '+50% dash speed', 'Time slows more while dashing', 'Can survive at 0 HP while dashing', 'C.W.B.I.D.B.S.C. breaks miniboss shields without harming them'],
		'type': 'saber',
		'max_stack': 1,
		'lore': ''
	},
	'overclocked_cooling': { # Faster CWBIDBSC cooldown
		'name': 'Overclocked Cooling',
		'desc': 'Expel both heat and remorse.',
		'effects': ['-20% C.W.B.I.D.B.S.C. cooldown'],
		'type': 'saber',
		'max_stack': 2
	},
	'ricochet_simulation': { # Boost saber ring deflection to level 2
		'name': 'Ricochet Simulation',
		'desc': 'Return to sender.',
		'effects': ['Saber ring deflects bullets back at their sources'],
		'type': 'saber',
		'max_stack': 1
	},
	'supple_telekinesis': { # Increases durability of saber ring
		'name': 'Supple Telekinesis',
		'desc': 'Better to bend than break.',
		'effects': [],
		'type': 'saber',
		'max_stack': 1
	},
}
