class_name Chunk
extends Node2D

enum ChunkType {NORMAL, EMPTY, OBJECTIVE, SPAWN, BOSS}

export (ChunkType) var chunk_type
export (NodePath) var init_player = null
export (NodePath) var boss = null
