extends Camera2D

export (NodePath) var init_anchor
onready var anchor = get_node(init_anchor)
onready var smooth_anchor_pos = anchor.global_position
var base_offset = Vector2.ZERO
var smooth_base_offset = base_offset

var mouse_follow = 0

func _ready():
	GameManager.camera = self

func _physics_process(delta):
	if anchor:
		base_offset = (get_global_mouse_position() - anchor.global_position)*mouse_follow
		smooth_anchor_pos = lerp(smooth_anchor_pos, anchor.global_position, 0.15)
		smooth_base_offset = lerp(smooth_base_offset, base_offset, 0.5)
		global_position = smooth_anchor_pos + base_offset


