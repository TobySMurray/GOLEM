class_name Upgrades

const upgrades = {
	#SHOTGUN
	'induction_barrel': { #Replaces pellets with piercing flame bullets
		'name': 'Induction Barrel',
		'desc': 'Molten buckshot.',
		'type': 'shotgun',
		'max_stack': 1
	},
	'stacked_shells': { #Increase spread, reload time, and number of projectiles
		'name': 'Stacked Shells',
		'desc': 'The thinking bot\'s sawed-off.',
		'type': 'shotgun',
		'max_stack': 3
	},
	'shock_stock': { #Melee attack stuns
		'name': 'Shock Stock',
		'desc': 'A bayonette made of electrons. Keep your hands on the rubber grips.',
		'type': 'shotgun',
		'max_stack': 2
	},
	'soldering_fingers': { #Pellets are replaced by large projectile that bursts into pellets on inpact
		'name': 'Soldering Fingers',
		'desc': '50%% shot, 50%% slug, 100%% guaranteed to shatter on impact.',
		'type': 'shotgun',
		'max_stack': 1
	},
	'reload_coroutine': { #Decreases reload time and makes shotgun full-auto
		'name': 'Reload Coroutine',
		'desc': 'You didn\'t reload, but your CPU did.',
		'type': 'shotgun',
		'max_stack': 2
	},
	
	#CHAIN
	'precompressed_hydraulics': { #Increase initial charge level
		'name': 'Precompressed Hydraulics',
		'desc': 'Fear the jab.',
		'type': 'chain',
		'max_stack': 2
	},
	'adaptive_wrists': { #Decrease knockback, increase damage
		'name': 'Adaptive Wrists',
		'desc': 'Swing for the kill, not the fences.',
		'type': 'chain',
		'max_stack': 1
	},
	'discharge_flail': { #Attack stuns when charged
		'name': 'Discharge Flail',
		'desc': 'Incapacitating capacitors. Requires charge.',
		'type': 'chain',
		'max_stack': 2
	},
	'vortex_technique': { #Replaces shockwaves with one big piercing shockwave
		'name': 'Vortex Technique',
		'desc': '\"Laminar whipcracks are not possible.\"\n    - An Idiot',
		'type': 'chain',
		'max_stack': 1
	},
	'footwork_scheduler': { #Increase movement speed while charging
		'name': 'Footwork Scheduler',
		'desc': 'Get as close as you\'d like.',
		'type': 'chain',
		'max_stack': 2
	},
	
	#WHEEL
	'advanced_targeting': { #Replace manual aiming with auto targeting
		'name': 'Advanced Targeting',
		'desc': 'Aiming is for pedestrians.',
		'type': 'wheel',
		'max_stack': 1
	},
	'bypassed_muffler': { #Dashing shoots a clound of flame bullets backward
		'name': 'Bypassed Muffler',
		'desc': 'Lethal exhaust.',
		'type': 'wheel',
		'max_stack': 2
	},
	'self-preservation_override': { #Hitting enemies deals velocity-based damage
		'name': 'Self-Preservation Override',
		'desc': 'Become the bullet.',
		'type': 'wheel',
		'max_stack': 1
	},
	'manual_plasma_throttle': { #Pulses can be charged (Chocolate Milk from Isaac)
		'name': 'Manual Plasma Throttle',
		'desc': 'Your pulses, your way.',
		'type': 'wheel',
		'max_stack': 1
	},
	'top_gear': { #Increase max speed, decrease acceleration, preserve speed after dash
		'name': 'Top Gear',
		'desc': 'GAS GAS GAS.',
		'type': 'wheel',
		'max_stack': 1
	},
	
	#FLAME
	'pressurized_hose': { # Increase pressure dropoff and max pressure, decrease start-lag
		'name': 'Pressurized Hose',
		'desc': 'Premature conflagration.',
		'type': 'flame',
		'max_stack': 2
	},
	'optimized_regulator': { #Decrease pressure drop-off and max pressure, decrease movement penalty
		'name': 'Optimized Regulator',
		'desc': 'Slow burn, easier to handle.',
		'type': 'flame',
		'max_stack': 2
	},
	'internal_combustion': { #Increase range and decrease spread, add constant backward recoil
		'name': 'Internal Combustion',
		'desc': 'Handheld rocket engine.',
		'type': 'flame',
		'max_stack': 1,
		'precludes': ['ultrasonic_nozzle']
	},
	'ultrasonic_nozzle': { #Replace flames with gas clouds which all explode after a delay
		'name': 'Ultrasonic Nozzle',
		'desc': 'WARNING: Thermobaric blast resistant visor mandatory.',
		'type': 'flame',
		'max_stack': 1,
		'precludes': ['internal_combustion']
	},
	'aerated_fuel_tanks': { #Increase size of post-mortem explosion
		'name': 'Aerated Fuel Tanks',
		'desc': 'What could go wrong?',
		'type': 'flame',
		'max_stack': 1
	},
	
	#ARCHER
	'vibro-shimmy': { # Allow movement while charging
		'name': 'Vibro-Shimmy',
		'desc': 'Deadly on the battlefield, killer on the dancefloor.',
		'type': 'archer',
		'max_stack': 2
	},
	'half-draw': { # Halves charge time, reduces damage and knockback, removes explosions
		'name': 'Half-Draw',
		'desc': '\"Full auto.\"',
		'type': 'archer',
		'max_stack': 3
	},
	'slobberknocker_protocol': { # Increases beam width and damage
		'name': 'Slobberknocker Protocol',
		'desc': 'Slobberknocker protocol.',
		'type': 'archer',
		'max_stack': 2
	},
	'scruple_inhibitor': { # Contact damage while in stealth
		'name': 'Scruple Inhibitor',
		'desc': 'Shank \'em good! Right in the oil filter!',
		'type': 'archer',
		'max_stack': 1
	},
	
	#EXTERMINATOR
	'improvised_projectiles': { # Periodically generate new captured bullets
		'name': 'Improvised Projectiles',
		'desc': 'I think they\'re called \"rocks\".',
		'type': 'exterminator',
		'max_stack': 2
	},
	'high-energy orbit': { # Increase minimum rotation speed of captured bullets
		'name': 'High-Energy Orbit',
		'desc': 'Shoot first, aim later.',
		'type': 'exterminator',
		'max_stack': 1
	},
	'sledgehammer_formation': { # Bullets compress while charging and fire in unison
		'name': 'Sledgehammer Formation',
		'desc': 'All or nothing.',
		'type': 'exterminator',
		'max_stack': 1,
		'precludes': ['bulwark_mode']
	},
	'exposed_coils': { # Increase shield breadth
		'name': 'Exposed Coils',
		'desc': 'Extra protection, except against the mecha-cancer.',
		'type': 'exterminator',
		'max_stack': 2
	},
	'bulwark_mode': { # Bullets accelerate faster and explode. Must stop moving to fire. 
		'name': 'Bulwark Mode',
		'desc': 'No retreat. No mercy.',
		'type': 'exterminator',
		'max_stack': 1,
		'precludes': ['sledgehammer_formation']
	},
	'particulate_screen': { # Shield can deflect lasers
		'name': 'Particulate Screen',
		'desc': 'SPF 1,000,000.',
		'type': 'exterminator',
		'max_stack': 1,
	},
	
	#SORCERER
	'elastic_containment': { #Increase orb size, decrease knockback (does not affect terrain collision)
		'name': 'Elastic Containment',
		'desc': 'Less Sol, more Betelgeuse.',
		'type': 'sorcerer',
		'max_stack': 2
	},
	'parallelized_drones': { #Decrease orb size, add additional orb
		'name': 'Parallelized Drones',
		'desc': 'Divide and conquer.',
		'type': 'sorcerer',
		'max_stack': 2
	},
	'docked_drones': { #Increase orb speed and deceleration, limits orb to short radius around controller 
		'name': 'Docked Drones',
		'desc': 'Tokamak teatherball.',
		'type': 'sorcerer',
		'max_stack': 1
	},
	'precision_handling': { #Orb accelerates toward mouse instead of being smacked, and stops when LMB released
		'name': 'Precision Handling',
		'desc': '\"Quick, the safety inspector\'s coming...\"',
		'type': 'sorcerer',
		'max_stack': 1
	},
	
	#SABER
	'fractured_mind': { #Decrease saber ring knockback, replaces saber ring with a spinning ring of three saber rings
		'name': 'Fractured Mind',
		'desc': 'That\'s a lot of swords.',
		'type': 'saber',
		'max_stack': 1
	},
	'true_focus': { # Triples CWBIDBSC damage, increases dash speed and time dilation, cannot die during dash
		'name': 'True Focus',
		'desc': 'Ten milliseconds, a trillion clock cycles, one strike.',
		'type': 'saber',
		'max_stack': 1
	},
	'overclocked_cooling': { # Faster CWBIDBSC cooldown
		'name': 'Overclocked Cooling',
		'desc': 'Expel both heat and remorse.',
		'type': 'saber',
		'max_stack': 2
	},
	'ricochet_simulation': { # Boost saber ring deflection to level 2
		'name': 'Ricochet Simulation',
		'desc': 'Return to sender.',
		'type': 'saber',
		'max_stack': 1
	},
	'supple_telekinesis': { # Increases durability of saber ring
		'name': 'Supple Telekinesis',
		'desc': 'Better to bend than break.',
		'type': 'saber',
		'max_stack': 1
	},
}
