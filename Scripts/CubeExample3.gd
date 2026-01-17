extends Interactable

func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = interaction_text

func perform_interaction():
	MonologueSystem.play_monologue("1a_Y_wake_up")
