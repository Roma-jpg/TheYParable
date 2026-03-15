extends Interactable

func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = interaction_text

func perform_interaction():
	MonologueSystem.play_and_wait_monologues(["painting_1", "painting_2", "painting_3", "painting_4"])
