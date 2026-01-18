extends Interactable

@export var switch := false

func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = interaction_text

func perform_interaction():
	if !switch:
		MaterialManager.make_objects_white()
		switch = true
	else:
		MaterialManager.revert_objects()
		switch = false
