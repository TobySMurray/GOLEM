class_name Chunk
extends Node2D

enum ChunkType {NORMAL, EMPTY, OBJECTIVE, SPAWN, BOSS}

@export var chunk_type : ChunkType
@export var init_player : NodePath
@export var boss : NodePath
