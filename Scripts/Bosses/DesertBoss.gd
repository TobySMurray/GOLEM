extends Boss

enum {
	INACTIVE,
	IDLE,
	RUN, #tries to get away from the player
	SUMMON, #spawns 4? small minions to swarm the player
	SPLIT, #once having taken enough damage, split into four mudbenders, with a big explosion
	ATTACK #not sure what this is yet (no animation)
	
}
