extends RichTextLabel



#thanks to Ragnar on the godot engine forums!

var lapsed = 0

func _ready():
	lapsed = 0

func start_text():
	lapsed = 0
	self.visible = true
	

func _physics_process(delta):
	if self.visible:
		lapsed += delta
		visible_characters = lapsed/0.1
